const axios = require("axios");
const BigNumber = require("bignumber.js");

const API_URL = "https://apiv5.paraswap.io";
const USER_ADDRESS = "0xe7804c37c13166fF0b37F5aE0BB07A3aEbb6e245";

const PARTNER = "chucknorris";
const SLIPPAGE = 1; // 1%

const Networks = {
  MAINNET: 1,
  POLYGON: 137
};

const tokens = {
  [Networks.MAINNET]: [
    {
      decimals: 18,
      symbol: "ETH",
      address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    },
    {
      decimals: 6,
      symbol: "USDC",
      address: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
    },
    {
      decimals: 18,
      symbol: "DAI",
      address: "0x6B175474E89094C44Da98b954EedeAC495271d0F"
    }
  ],
  [Networks.POLYGON]: [
    {
      decimals: 18,
      symbol: "MATIC",
      address: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"
    },
    {
      decimals: 8,
      symbol: "WBTC",
      address: "0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6"
    }
  ]
};

function getToken(symbol, networkID = Networks.MAINNET) {
  const token = tokens[networkID]?.find((t) => t.symbol === symbol);

  if (!token)
    throw new Error(`Token ${symbol} not available on network ${networkID}`);
  return token;
}

function createSwapper(networkID, apiURL) {
  const getRate = async ({ srcToken, destToken, srcAmount, partner = PARTNER }) => {
    const queryParams = {
      srcToken: srcToken.address,
      destToken: destToken.address,
      srcDecimals: srcToken.decimals.toString(),
      destDecimals: destToken.decimals.toString(),
      amount: srcAmount,
      side: "SELL",
      network: networkID.toString(),
      partner
    };

    const searchString = new URLSearchParams(queryParams);

    const pricesURL = `${apiURL}/prices/?${searchString}`;
    console.log("GET /price URL", pricesURL);

    const { data: { priceRoute } } = await axios.get(`${pricesURL}`);

    return priceRoute;
  };

  const buildSwap = async ({ srcToken, destToken, srcAmount, minAmount, priceRoute, userAddress, receiver, partner }) => {
    const txURL = `${apiURL}/transactions/${networkID}`;

    const txConfig = {
      priceRoute,
      srcToken: srcToken.address,
      srcDecimals: srcToken.decimals,
      destToken: destToken.address,
      destDecimals: destToken.decimals,
      srcAmount,
      destAmount: minAmount,
      userAddress,
      partner,
      receiver
    };

    const { data } = await axios.post(`${txURL}`, txConfig);

    return data;
  };

  return { getRate, buildSwap };
}

async function getSwapTransaction({ srcToken: srcTokenSymbol, destToken: destTokenSymbol, srcAmount: _srcAmount, networkID, slippage = SLIPPAGE, ...rest }) {
  try {
    const srcToken = getToken(srcTokenSymbol, networkID);
    const destToken = getToken(destTokenSymbol, networkID);

    const srcAmount = new BigNumber(_srcAmount).times(10 ** srcToken.decimals).toFixed(0);

    const ps = createSwapper(networkID, API_URL);

    const priceRoute = await ps.getRate({ srcToken, destToken, srcAmount });

    const minAmount = new BigNumber(priceRoute.destAmount).times(1 - slippage / 100).toFixed(0);

    const transactionRequest = await ps.buildSwap({
      srcToken,
      destToken,
      srcAmount,
      minAmount,
      priceRoute,
      ...rest
    });

    console.log("TransactionRequest", transactionRequest);

    return transactionRequest;
  } catch (error) {
    console.error(error.response.data);
    throw new Error(error.response.data.error);
  }
}

async function getExampleSwapTransaction() {
  return getSwapTransaction({
    srcAmount: srcAmount,
    srcToken: srcToken,
    destToken: destToken,
    networkID: Networks.POLYGON,
    userAddress: USER_ADDRESS
  });
}

module.exports = {
  getSwapTransaction,
  getExampleSwapTransaction
};
