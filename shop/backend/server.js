const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const productRoutes = require('./routes/products');
const categoryRoutes = require('./routes/categories');
const transactionRoutes = require('./routes/transactions');
const Product = require('./models/product');
const Category = require('./models/category');

const app = express();
const PORT = 4000;
const DB_URI = 'mongodb://localhost:27017/shop';

app.use(cors());
app.use(express.json());
app.use('/api/products', productRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api', transactionRoutes);

// Connect to MongoDB
mongoose.connect(DB_URI)

mongoose.connection.on('connected', () => {
  console.log('Connected to MongoDB');
  seedData();
});

mongoose.connection.on('error', (err) => {
  console.error(`Error connecting to MongoDB: ${err.message}`);
});

async function seedData() {
  try {
    await mongoose.connection.once('open', () => {
      console.log('Database connection established');
    });

    // Drop existing collections
    await mongoose.connection.db.dropCollection('products');
    await mongoose.connection.db.dropCollection('categories');
    console.log('Existing collections dropped');

    // Recreate collections
    await Product.createCollection();
    await Category.createCollection();
    console.log('Collections recreated');

    // Default categories
    const defaultCategories = [
      { id: 1, name: 'AGD' },
      { id: 2, name: 'Kitchen' },
    ];

    // Seed categories
    const categoryDocs = [];
    for (const category of defaultCategories) {
      const newCategory = await Category.create(category);
      categoryDocs.push(newCategory);
    }

    // Seed products
    const defaultProducts = [
      { id: 1, name: '4K TV', description: '144Hz', price: 1000, category: 'AGD' },
      { id: 2, name: 'Cup', price: 10, category: 'Kitchen' },
      { id: 3, name: 'Knife', price: 12.99, category: 'Kitchen' },
    ];

    for (const product of defaultProducts) {
      const categoryDoc = categoryDocs.find(cat => cat.name === product.category);
      if (categoryDoc) {
        const newProduct = { ...product, category: categoryDoc._id };
        await Product.create(newProduct);
      } 
    }

    console.log('Default data seeded successfully!');
  } catch (err) {
    console.error('Error seeding data:', err);
  }
}

// Start server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});