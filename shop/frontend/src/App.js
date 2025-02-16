import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';
import ProductList from './ProductList';
import ShoppingCart from './ShoppingCart';

function App() {
  const [products, setProducts] = useState([]);
  const [cart, setCart] = useState([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchProducts();
  }, []);

  useEffect(() => {
    calculateTotal(cart);
  }, [cart]);

  const fetchProducts = async () => {
    try {
      setLoading(true);
      const response = await axios.get('http://localhost:4000/api/products');
      console.log('Fetched products:', response.data); 
      setProducts(response.data);
      setError(null);
    } catch (error) {
      console.error('Error fetching products:', error);
      setError('Failed to load products. Please try again later.');
    } finally {
      setLoading(false);
    }
  };

  const addToCart = (product, quantity) => {
    setCart((prevCart) => {
      const existingProductIndex = prevCart.findIndex(
        (item) => item._id === product._id
      );

      if (existingProductIndex !== -1) {
        const updatedCart = [...prevCart];
        updatedCart[existingProductIndex].quantity += quantity;
        return updatedCart;
      } else {
        const newProduct = { ...product, quantity };
        return [...prevCart, newProduct];
      }
    });
  };

  const removeFromCart = (id) => {
    setCart((prevCart) => prevCart.filter((item) => item.id !== id));
  };

  const calculateTotal = (cart) => {
    const totalPrice = cart.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0
    );
    setTotal(totalPrice);
  };

  const handleCheckout = async () => {
    try {
      const userDetails = {};
      await axios.post('http://localhost:4000/api/submit-transaction', {
        cartItems: cart,
        totalAmount: total,
        userDetails,
      });
      alert(`Payment completed successfully. \nTotal amount paid: $${total.toFixed(2)}`);
      setCart([]);
      setTotal(0);
    } catch (error) {
      console.error('Error during checkout:', error);
      alert('Error during checkout. Please try again.');
    }
  };

  return (
    <div className="App">
      <h1>Shop</h1>
      {loading && <p>Loading products...</p>}
      {error && <p className="error">{error}</p>}
      {!loading && !error && (
        <>
          <ProductList products={products} addToCart={addToCart} />
          <ShoppingCart 
            cart={cart} 
            removeFromCart={removeFromCart} 
            total={total} 
            handleCheckout={handleCheckout} 
          />
        </>
      )}
    </div>
  );
}

export default App;