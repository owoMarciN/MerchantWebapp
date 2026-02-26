const { onRequest } = require("firebase-functions/v2/https");
const fetch = require("node-fetch");
const { defineSecret } = require("firebase-functions/params");

const GOOGLE_MAPS_KEY = defineSecret("GOOGLE_MAPS_KEY");

exports.googleMapsAutocomplete = onRequest(
  { 
    region: "europe-west1",
    secrets: [GOOGLE_MAPS_KEY] 
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") return res.status(204).send("");

    const input = req.query.input;
    if (!input) return res.status(400).json({ error: "Missing input" });

    try {
      const apiKey = GOOGLE_MAPS_KEY.value(); 
      const url = `https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${encodeURIComponent(input)}&key=${apiKey}`;
      const response = await fetch(url);
      const data = await response.json();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ error: "Failed" });
    }
  }
);

exports.googleMapsDetails = onRequest(
  { 
    region: "europe-west1",
    secrets: [GOOGLE_MAPS_KEY] 
  },
  async (req, res) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") return res.status(204).send("");

    const placeId = req.query.placeId;
    if (!placeId) return res.status(400).json({ error: "Missing placeId" });

    try {
      const apiKey = GOOGLE_MAPS_KEY.value(); 
      const url = `https://maps.googleapis.com/maps/api/place/details/json?place_id=${placeId}&key=${apiKey}`;
      const response = await fetch(url);
      const data = await response.json();
      res.status(200).json(data);
    } catch (error) {
      res.status(500).json({ error: "Failed to fetch details" });
    }
  }
);