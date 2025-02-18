from typing import Text, Dict, Any, List
from rasa_sdk import Action, Tracker
from rasa_sdk.executor import CollectingDispatcher
from rasa_sdk.events import SlotSet
import json
from datetime import datetime, timedelta
import os

#Load data
try:
    config_directory = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "config"))
    os.chdir(config_directory)
    menu_path = os.path.join(config_directory, 'menu.json')
    opening_hours_path = os.path.join(config_directory, 'opening_hours.json')

    with open(menu_path, 'r') as f:
        MENU_DATA = json.load(f)

    with open(opening_hours_path, 'r') as f:
        OPENING_HOURS_DATA = json.load(f)

except FileNotFoundError:
    print("ERROR: menu.json or opening_hours.json not found!")
    MENU_DATA = {"items": []}
    OPENING_HOURS_DATA = {"items": {}}
except json.JSONDecodeError:
    print("ERROR: menu.json or opening_hours.json contains invalid JSON!")
    MENU_DATA = {"items": []}
    OPENING_HOURS_DATA = {"items": {}}
except Exception as e:
    print(f"ERROR: {e}")
    MENU_DATA = {"items": []}
    OPENING_HOURS_DATA = {"items":{}}

class ActionShowOpeningHours(Action):
    def name(self) -> Text:
        return "action_opening_hours"

    def run(self, dispatcher, tracker, domain):
        output = "We are open:\n"
        for day, hours in OPENING_HOURS_DATA["items"].items():
            if hours["open"] == 0 and hours["close"] == 0:
                output += f"- {day}: Closed\n"
            else:
                output += f"- {day}: {hours['open']} - {hours['close']}\n"

        dispatcher.utter_message(text=output)

class ActionCheckOpeningHours(Action):
    def name(self) -> Text:
        return "action_check_open"

    def run(self, dispatcher, tracker, domain):        
        day = tracker.get_slot("day") or datetime.now().strftime("%A")
        day_data = OPENING_HOURS_DATA["items"].get(day)
        
        if day_data:
            response = f"We're open from {day_data['open']}:00 to {day_data['close']}:00 on {day}"
        else:
            response = "Sorry, we're closed that day"
            
        dispatcher.utter_message(text=response)

class ActionShowMenu(Action):
    def name(self) -> Text:
        return "action_show_menu"

    def run(self, dispatcher, tracker, domain):      
        menu_items = "\n".join(
            [f"- {item['name']}: ${item['price']}" 
             for item in MENU_DATA["items"]]
        )
        dispatcher.utter_message(text=f"Here's our menu:\n{menu_items}")

class ActionProcessOrder(Action):
    def name(self) -> Text:
        return "action_process_order"

    def run(self, dispatcher: CollectingDispatcher,
            tracker: Tracker,
            domain: Dict[Text, Any]) -> List[Dict[Text, Any]]:

        dish = tracker.get_slot("dish")
        quantity = tracker.get_slot("quantity")
        
        # --- Input Validation and Normalization ---
        if not dish:
            dispatcher.utter_message(text="Please specify the dish you'd like to order.")
            return []
        
        if quantity is None:
            quantity = 1  # Default to 1 if not specified

        try:
            quantity = float(quantity)
        except (ValueError, TypeError):
            dispatcher.utter_message(text="I didn't understand the quantity.  Please enter a valid number.")
            return [SlotSet("quantity", None)]

        # --- Building the order_items list ---
        order_items = tracker.get_slot("order_items") or []  # Initialize if it doesn't exist

        # Check if the dish exists in the menu
        menu_item = next((item for item in MENU_DATA["items"] if item["name"].lower() == dish.lower()), None)
        if not menu_item:
            dispatcher.utter_message(text=f"Sorry, we don't have {dish} on the menu.")
            return [SlotSet("dish", None)] # Clear invalid dish.

        # Create or update the item in the order_items list
        found = False
        for item in order_items:
            if item["dish"].lower() == dish.lower():
                item["quantity"] += quantity  # Add to existing quantity
                found = True
                break
        if not found:
            order_items.append({"dish": dish, "quantity": quantity}) #new item

        # --- Calculation and Response ---
        total = 0
        total_preparation_time_hours = 0

        for item in order_items:
            menu_item = next((i for i in MENU_DATA["items"] if i["name"].lower() == item["dish"].lower()), None)
            total += menu_item["price"] * item["quantity"]
            total_preparation_time_hours += menu_item["preparation_time"] * item["quantity"] # Total time in *hours*

        ready_time = (datetime.now() + timedelta(hours=total_preparation_time_hours)).strftime("%H:%M")

        # --- Build the confirmation message ---
        order_summary = "\n".join([f"- {item['quantity']} x {item['dish']}" for item in order_items])

        response = (
            f"Order confirmed!\n"
            f"Items:\n{order_summary}\n"
            f"Total: ${total:.2f}\n"
            f"Ready for pickup at: {ready_time}"
        )

        dispatcher.utter_message(text=response)
