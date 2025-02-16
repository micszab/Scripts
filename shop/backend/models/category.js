const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema({
  id: {type: Number, required: true},
  name: { type: String, required: true }
}, { 
  versionKey: false
});

module.exports = mongoose.model('Category', categorySchema);