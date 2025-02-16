import React, { useState } from 'react';
import PropTypes from 'prop-types';

function ProductList({ products, addToCart }) {
  const [quantities, setQuantities] = useState({});

  const handleQuantityChange = (productId, value) => {
    setQuantities({
      ...quantities,
      [productId]: value,
    });
  };

  const handleAddToCart = (product) => {
    const quantity = quantities[product.id] ? parseInt(quantities[product.id], 10) : 1;
    addToCart(product, quantity);
  };

  return (
    <div className="product-list">
      {products.map((product) => (
        <div key={product.id || product.name} className="product-item">
          <div className="category">{product.category.name}</div>
          <h2>{product.name}</h2>
          <p className="description">Description: {product.description || ''}</p>
          <p>Price: ${product.price.toFixed(2)}</p>
          <div className="product-actions">
            <input
              type="number"
              min="1"
              value={quantities[product.id] || 1}
              onChange={(e) => handleQuantityChange(product.id, e.target.value)}
              className="quantity-input"
            />
            <button onClick={() => handleAddToCart(product)} className="add-to-cart-button">Add to Cart</button>
          </div>
        </div>
      ))}
    </div>
  );
}

ProductList.propTypes = {
  products: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.number.isRequired,
      name: PropTypes.string.isRequired,
      price: PropTypes.number.isRequired,
      category: PropTypes.shape({
        name: PropTypes.string.isRequired,
      }).isRequired,
      description: PropTypes.string,
    })
  ).isRequired,
  addToCart: PropTypes.func.isRequired,
};

export default ProductList;