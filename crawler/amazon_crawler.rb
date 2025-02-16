#!/usr/bin/env ruby
require 'nokogiri'
require 'open-uri'
require 'sequel'

DB = Sequel.sqlite('products.db')
DB.create_table? :products do
  primary_key :id
  String :title
  Float :price
  String :url
  Text :details
end

class Product < Sequel::Model(:products); end

def fetch_and_save_products(keyword)
  base_url = build_amazon_url(keyword)
  user_agent = user_agent_string
  doc = fetch_page(base_url, user_agent)

  process_product_cards(doc)
  puts 'Product data has been saved to the SQLite database.'
end

def build_amazon_url(keyword)
  "https://www.amazon.com/s?k=#{URI::DEFAULT_PARSER.escape(keyword)}"
end

def user_agent_string
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.5938.62 Safari/537.36"
end

def fetch_page(url, user_agent)
  Nokogiri::HTML(URI.open(url, "User-Agent" => user_agent))
end

def process_product_cards(doc)
  doc.css('div.s-main-slot div[data-component-type="s-search-result"]').each do |product_card|
    title = extract_title(product_card)
    price = extract_price(product_card)
    url = extract_url(product_card)

    save_product(title, price, url) if price
  end
end

def extract_title(product_card)
  title_element = product_card.at_css('h2 a.a-link-normal span')
  title_element ? title_element.text.strip : 'No title'
end

def extract_price(product_card)
  price_whole = product_card.at_css('span.a-price-whole')&.text
  price_fraction = product_card.at_css('span.a-price-fraction')&.text
  price_whole && price_fraction ? "#{price_whole}.#{price_fraction}".to_f : nil
end

def extract_url(product_card)
  "https://www.amazon.com#{product_card.at_css('h2 a.a-link-normal')[:href]}"
end

def save_product(title, price, url)
  Product.create(title: title, price: price, url: url)
end

def display_products
  puts "Products saved in the database:"
  Product.each do |product|
    puts "Product: #{product.title}"
    puts "Price: #{product.price} USD"
    puts "URL: #{product.url}"
    puts "-" * 10
  end
end

def prompt_for_keyword
  puts 'Enter a keyword to search for products on Amazon:'
  keyword = gets.chomp
end

def main
  keyword = prompt_for_keyword
  fetch_and_save_products(keyword)

  display_products
end

main
