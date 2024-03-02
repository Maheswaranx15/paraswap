const express = require('express');
const bodyParser = require('body-parser');
const API = require('./api');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(express.json());


app.post('/swap-transaction', async (req, res) => {
  try {
    const { srcAmount, srcToken, destToken, networkID, userAddress } = req.body;

    if (!srcAmount || !srcToken || !destToken || !networkID || !userAddress) {
      return res.status(400).json({ error: 'Missing required parameters' });
    }

    const txRequest = await API.getSwapTransaction({
      srcAmount,
      srcToken,
      destToken,
      networkID,
      userAddress
    });

    res.json(txRequest);
  } catch (error) {
    console.error("Error in swap-transaction:", error);
    res.status(500).json({ error: 'An error occurred' });
  }
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
