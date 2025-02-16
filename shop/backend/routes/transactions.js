const express = require('express');
const router = express.Router();

// Submit transaction
router.post('/submit-transaction', async (req, res) => {
  try {
    const { cartItems, totalAmount, userDetails } = req.body;
    res.status(200).json({ message: 'Transaction completed successfully' });
  } catch (err) {
    res.status(500).json({ message: 'Error processing transaction', error: err.message });
  }
});

module.exports = router;