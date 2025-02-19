#!/usr/bin/ruby
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
  doc.css('div[data-component-type="s-search-result"]').each do |product_card|
    next if product_card.at_css('[aria-label="Sponsored"]')

    title = extract_title(product_card)
    price = extract_price(product_card)
    url = extract_url(product_card)

    # Only save if the product is valid (including URL check)
    if valid_product?(title, price, url)
      save_product(title, price, url)
    else
      puts "Skipping invalid product: #{title.inspect} - URL: #{url.inspect}"
    end
  end
end

def valid_product?(title, price, url)
  ![title, price, url].any?(&:nil?) && 
  title != 'No title' && 
  !url.to_s.empty? && 
  price.to_f > 0 && 
  !url.to_s.include?('/sspa/click') && 
  !url.to_s.include?('/gp/slredirect/') && 
  !url.to_s.include?('/ad/dp/')
end

def extract_title(product_card)
  title_element = product_card.at_css('h2.a-size-medium span')

  if title_element
    title = title_element.text.strip
    title = title.gsub(/\uFFFD/, '').strip
    title = title.gsub(/Sponsored$/, '').strip 
    return title unless title.empty?
  end

  return 'No title'
end

def extract_price(product_card)
  price_text = product_card.at_css('.a-price .a-offscreen')&.text
  return nil unless price_text
  
  price_text.scan(/[\d\.]+/).join.to_f
end

def extract_url(product_card)
  link = product_card.at_css('h2 a.a-link-normal') || 
         product_card.at_css('a.s-no-outline')
  return nil unless link
  
  uri = link['href'].split('?').first
  "https://www.amazon.com#{uri}"
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
