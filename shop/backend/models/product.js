const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  id: {type: Number, required: true},
  name: { type: String, required: true },
  description: { type: String },
  price: { type: Number, required: true },
  category: { type: mongoose.Schema.Types.ObjectId, ref: 'Category', required: true }
}, { 
  versionKey: false
});

module.exports = mongoose.model('Product', productSchema);