const crypto = require("crypto");

function getAlgorithm(keyBytes) {
  switch (keyBytes.length) {
    case 16:
      return "aes-128-cbc";
    case 24:
      return "aes-192-cbc";
    case 32:
      return "aes-256-cbc";
    default:
      throw new Error(`Invalid secret key length: ${keyBytes.length}`);
  }
}

function resolveSecretKey(secret) {
  // Zego app sign is commonly a 64-char hex string; decode it to 32 raw bytes.
  if (/^[0-9a-fA-F]{64}$/.test(secret)) {
    return Buffer.from(secret, "hex");
  }
  return Buffer.from(secret, "utf8");
}

function makeRandomIv() {cd /Users/macbook/Desktop/backend_AgentAi
  git push
  const chars = "0123456789abcdefghijklmnopqrstuvwxyz";
  let iv = "";
  for (let i = 0; i < 16; i += 1) {
    iv += chars[Math.floor(Math.random() * chars.length)];
  }
  return iv;
}

function aesEncrypt(plainText, keyBytes, iv) {
  const cipher = crypto.createCipheriv(
    getAlgorithm(keyBytes),
    keyBytes,
    Buffer.from(iv, "utf8")
  );
  cipher.setAutoPadding(true);
  return Buffer.concat([cipher.update(plainText, "utf8"), cipher.final()]);
}

function generateToken04(appID, userID, secret, effectiveTimeInSeconds, payload = "") {
  const createTime = Math.floor(Date.now() / 1000);
  const tokenInfo = {
    app_id: appID,
    user_id: userID,
    nonce: Math.floor(Math.random() * 4294967295) - 2147483648,
    ctime: createTime,
    expire: createTime + effectiveTimeInSeconds,
    payload
  };

  const plainText = JSON.stringify(tokenInfo);
  const iv = makeRandomIv();
  const keyBytes = resolveSecretKey(secret);
  const encrypted = aesEncrypt(plainText, keyBytes, iv);
  const ivBytes = Buffer.from(iv, "utf8");

  const expireBytes = Buffer.alloc(8);
  expireBytes.writeBigInt64BE(BigInt(tokenInfo.expire), 0);

  const ivLenBytes = Buffer.alloc(2);
  ivLenBytes.writeUInt16BE(ivBytes.length, 0);

  const encLenBytes = Buffer.alloc(2);
  encLenBytes.writeUInt16BE(encrypted.length, 0);

  const bin = Buffer.concat([expireBytes, ivLenBytes, ivBytes, encLenBytes, encrypted]);
  return `04${bin.toString("base64")}`;
}

exports.handler = async (event) => {
  const headers = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST,OPTIONS",
    "Content-Type": "application/json"
  };

  if (event.httpMethod === "OPTIONS") {
    return { statusCode: 204, headers, body: "" };
  }

  try {
    const { userID } = JSON.parse(event.body || "{}");
    if (!userID || typeof userID !== "string") {
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: "Missing or invalid userID" })
      };
    }

    const appID = 1789528352;
    const secret = "0b0859483bba588d97ed478e8b69da06"; // Zego ServerSecret (32-char)
    const token = generateToken04(appID, userID, secret, 3600, "");

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ token })
    };
  } catch (error) {
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ error: "Failed to generate token", detail: String(error) })
    };
  }
};
