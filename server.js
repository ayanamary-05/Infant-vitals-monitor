const admin = require('firebase-admin');
const express = require('express');
const serviceAccount = require('./serviceAccountKey.json'); // download from Firebase

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: 'https://YOUR_PROJECT_ID-default-rtdb.firebaseio.com'
});

const db = admin.database();
const app = express();
app.use(express.json());

// Normal ranges for infants
const RANGES = {
  heartRate:   { min: 100, max: 160 },
  spo2:        { min: 95,  max: 100 },
  temperature: { min: 36.5, max: 37.5 },
};

// Watch Firebase for new vitals
db.ref('vitals/latest').on('value', async (snapshot) => {
  const vitals = snapshot.val();
  if (!vitals) return;

  const alerts = [];

  for (const [key, range] of Object.entries(RANGES)) {
    const val = parseFloat(vitals[key]);
    if (isNaN(val)) continue;

    if (val < range.min) alerts.push(`⚠️ Low ${key}: ${val}`);
    if (val > range.max) alerts.push(`⚠️ High ${key}: ${val}`);
  }

  if (alerts.length > 0) {
    await db.ref('alerts').set({
      active: true,
      message: alerts.join(' | '),
      timestamp: new Date().toISOString(),
    });
    console.log('ALERT triggered:', alerts);
  } else {
    await db.ref('alerts').set({ active: false, message: '' });
  }
});

// REST endpoint to get latest vitals
app.get('/api/vitals', async (req, res) => {
  const snap = await db.ref('vitals/latest').get();
  res.json(snap.val());
});

// REST endpoint to get history
app.get('/api/vitals/history', async (req, res) => {
  const snap = await db.ref('vitals/history').limitToLast(50).get();
  res.json(snap.val());
});

app.listen(3000, () => console.log('Server running on port 3000'));