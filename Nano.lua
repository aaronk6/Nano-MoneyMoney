-- Inofficial Nano Extension for MoneyMoney
-- Fetches balances from mynano.ninja and returns them as securities
--
-- Copyright (c) 2023 aaronk6, marothe
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking{
  version = 1.03,
  description = "Fetches balances from mynano.ninja and returns them as securities",
  services = { "Nano" },
}

local currencyName = "Nano"
local currency = "EUR" -- fixme: Don't hardcode
local currencyField = "eur"
local currencyId = "nano"
local marketName = "CoinGecko"
local priceUrl = "https://api.coingecko.com/api/v3/simple/price?ids=" .. currencyId .. "&vs_currencies=" .. currencyField
local balanceUrl = "https://mynano.ninja/api/node"
local postContentType = "application/json"
local jsonObject = {}
jsonObject["action"] = "account_balance"

local addresses
local balances

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Nano"
end

function InitializeSession (protocol, bankCode, username, username2, password, username3)
  addresses = strsplit(",%s*", username)
end

function ListAccounts (knownAccounts)
  local account = {
    name = currencyName,
    accountNumber = currencyName,
    currency = currency,
    portfolio = true,
    type = "AccountTypePortfolio"
  }

  return {account}
end

function RefreshAccount (account, since)
  local s = {}
  local prices = queryPrices()
  local balances = queryBalances(addresses)

  for i,v in ipairs(addresses) do
    s[i] = {
      name = v,
      currency = nil,
      market = marketName,
      quantity = balances[i] / 1000000000000000000000000000000,
      price = prices[currencyField],
    }
  end

  return {securities = s}
end

function EndSession ()
end

function queryPrices()
  local connection = Connection()
  local res = JSON(connection:request("GET", priceUrl))
  return res:dictionary()[currencyId]
end

function queryBalances(addresses)
  local connection = Connection()
  local balances = {}
  local res

  for key, address in pairs(addresses) do
    jsonObject["account"]=address
    local jsonString = JSON():set(jsonObject):json()
    
    res = JSON(connection:request("POST", balanceUrl, jsonString, postContentType))
    table.insert(balances, res:dictionary()["balance"])
  end

  return balances
end

-- from http://lua-users.org/wiki/SplitJoin
function strsplit(delimiter, text)
  local list = {}
  local pos = 1
  if string.find("", delimiter, 1) then -- this would result in endless loops
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    if first then -- found?
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
end