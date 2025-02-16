import React from 'react';

function ShoppingCart({ cart, total, handleCheckout, removeFromCart }) {
  return (
    <div className="cart">
      {cart.length === 0 ? (
        <p>Empty</p>
      ) : (
        <div>
          {cart.map((item) => (
            <div key={item.id} className="cart-item">
              <p>{item.name} - ${item.price} (Quantity: {item.quantity})</p>
              <button onClick={() => removeFromCart(item.id)}>Remove from cart</button>
            </div>
          ))}
        </div>
      )}
      <p>Total: ${total.toFixed(2)}</p>
      <button className="checkout" onClick={handleCheckout}>Submit</button>
    </div>
  );
}

export default ShoppingCart;