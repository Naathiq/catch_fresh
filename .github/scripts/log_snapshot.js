// .github/scripts/log_snapshot.js
// Autonomous snapshot logger for Catch Fresh (Aquaculture IoT)
// Runs 4 times a day via GitHub Actions at 06:00, 12:00, 18:00, 00:00 IST.
// Cost: $0.00 (within Firebase Spark Free Plan & GitHub Actions Free Tier).

const FIREBASE_BASE_URL = 'https://fish-9705a-default-rtdb.firebaseio.com';

async function fetchJson(path) {
  try {
    const res = await fetch(`${FIREBASE_BASE_URL}${path}`);
    if (!res.ok) throw new Error(`HTTP error ${res.status}`);
    return await res.json();
  } catch (err) {
    console.error(`Error fetching ${path}:`, err.message);
    return null;
  }
}

async function putJson(path, data) {
  const res = await fetch(`${FIREBASE_BASE_URL}${path}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) throw new Error(`Failed to write to ${path}: HTTP ${res.status}`);
  return await res.json();
}

// Math Engine: App-side TDS Calculation (matches overview_screen.dart)
function calculateTDS(voltage, calData) {
  if (!voltage || voltage < 0.01) return 0.0;

  if (!calData || calData.enabled !== true || (calData.pointCount || 0) < 3) {
    return Math.max(
      0.0,
      (133.42 * Math.pow(voltage, 3) - 255.86 * Math.pow(voltage, 2) + 857.39 * voltage) * 0.5
    );
  }

  const pts = [];
  const raw = calData.points;
  if (Array.isArray(raw)) {
    for (const item of raw) {
      if (item) pts.push({ v: Number(item.compensatedVoltage || 0), p: Number(item.referencePPM || 0) });
    }
  } else if (raw && typeof raw === 'object') {
    for (const k of Object.keys(raw)) {
      if (raw[k]) pts.push({ v: Number(raw[k].compensatedVoltage || 0), p: Number(raw[k].referencePPM || 0) });
    }
  }

  pts.sort((a, b) => a.v - b.v);
  if (pts.length < 3) return 0.0;

  if (voltage < pts[0].v) {
    if (pts[0].v === 0) return 0.0;
    return Math.max(0.0, voltage * (pts[0].p / pts[0].v));
  }

  for (let i = 0; i < pts.length - 1; i++) {
    const x1 = pts[i].v, x2 = pts[i + 1].v;
    const y1 = pts[i].p, y2 = pts[i + 1].p;
    if (voltage >= x1 && voltage <= x2) {
      return Math.max(0.0, y1 + (voltage - x1) * (y2 - y1) / (x2 - x1));
    }
  }

  const l = pts.length - 1;
  return Math.max(0.0, pts[l - 1].p + (voltage - pts[l - 1].v) * (pts[l].p - pts[l - 1].p) / (pts[l].v - pts[l - 1].v));
}

// Math Engine: App-side Temperature Calculation (matches overview_screen.dart)
function calculateTemp(rawTemp, tempCalData) {
  if (!rawTemp || isNaN(rawTemp)) return 0.0;
  if (!tempCalData || tempCalData.enabled !== true) return Number(rawTemp);

  const pts = [];
  const raw = tempCalData.points;
  if (Array.isArray(raw)) {
    for (const item of raw) {
      if (item) pts.push({ f: Number(item.factoryTemp || 0), r: Number(item.referenceTemp || 0) });
    }
  } else if (raw && typeof raw === 'object') {
    for (const k of Object.keys(raw)) {
      if (raw[k]) pts.push({ f: Number(raw[k].factoryTemp || 0), r: Number(raw[k].referenceTemp || 0) });
    }
  }

  if (pts.length === 0) return Number(rawTemp);
  pts.sort((a, b) => a.f - b.f);

  if (pts.length === 1) return Number(rawTemp) + (pts[0].r - pts[0].f);
  if (rawTemp < pts[0].f) {
    return pts[0].r + (rawTemp - pts[0].f) * (pts[1].r - pts[0].r) / (pts[1].f - pts[0].f);
  }

  for (let i = 0; i < pts.length - 1; i++) {
    if (rawTemp >= pts[i].f && rawTemp <= pts[i + 1].f) {
      return pts[i].r + (rawTemp - pts[i].f) * (pts[i + 1].r - pts[i].r) / (pts[i + 1].f - pts[i].f);
    }
  }

  const l = pts.length - 1;
  return pts[l - 1].r + (rawTemp - pts[l - 1].f) * (pts[l].r - pts[l - 1].r) / (pts[l].f - pts[l - 1].f);
}

// Math Engine: App-side pH Calculation (matches overview_screen.dart)
function calculatePH(voltage, phCalData) {
  if (!voltage || voltage < 0.1) return 0.0;
  if (!phCalData || phCalData.enabled !== true) {
    return 7.0 + ((2.5 - voltage) / 0.18);
  }

  const pts = [];
  const raw = phCalData.points;
  if (Array.isArray(raw)) {
    for (const item of raw) {
      if (item) pts.push({ v: Number(item.voltage || 0), p: Number(item.referencePH || 0) });
    }
  } else if (raw && typeof raw === 'object') {
    for (const k of Object.keys(raw)) {
      if (raw[k]) pts.push({ v: Number(raw[k].voltage || 0), p: Number(raw[k].referencePH || 0) });
    }
  }

  if (pts.length === 0) return 7.0;
  pts.sort((a, b) => a.v - b.v);

  if (voltage < pts[0].v) {
    if (pts.length === 1) return pts[0].p;
    return pts[0].p + (voltage - pts[0].v) * (pts[1].p - pts[0].p) / (pts[1].v - pts[0].v);
  }

  for (let i = 0; i < pts.length - 1; i++) {
    if (voltage >= pts[i].v && voltage <= pts[i + 1].v) {
      return pts[i].p + (voltage - pts[i].v) * (pts[i + 1].p - pts[i].p) / (pts[i + 1].v - pts[i].v);
    }
  }

  const l = pts.length - 1;
  return pts[l - 1].p + (voltage - pts[l - 1].v) * (pts[l].p - pts[l - 1].p) / (pts[l].v - pts[l - 1].v);
}

async function runLogger() {
  console.log('--- Catch Fresh Autonomous Milestone Logger ---');

  // Fetch live telemetry & calibration concurrently
  const [device01Live, device02Live, tdsCal, tempCal, phCal] = await Promise.all([
    fetchJson('/device01/live.json'),
    fetchJson('/device02/live.json'),
    fetchJson('/device01/calibration.json'),
    fetchJson('/device01/tempCalibration.json'),
    fetchJson('/device02/calibration.json'),
  ]);

  if (!device01Live && !device02Live) {
    console.error('Error: Neither device01 nor device02 data could be fetched.');
    process.exit(1);
  }

  // Calculate IST Date and Milestone (UTC+5:30)
  const now = new Date();
  const istOffset = 5.5 * 60 * 60 * 1000;
  const istDate = new Date(now.getTime() + istOffset);

  const year = istDate.getUTCFullYear();
  const month = String(istDate.getUTCMonth() + 1).padStart(2, '0');
  const day = String(istDate.getUTCDate()).padStart(2, '0');
  const hour = istDate.getUTCHours();
  const minute = String(istDate.getUTCMinutes()).padStart(2, '0');

  // Determine Milestone Slot
  let milestone = 'Morning';
  let slotTime = '06:00';
  if (hour >= 9 && hour < 15) {
    milestone = 'Midday';
    slotTime = '12:00';
  } else if (hour >= 15 && hour < 21) {
    milestone = 'Evening';
    slotTime = '18:00';
  } else if (hour >= 21 || hour < 4) {
    milestone = 'Midnight';
    slotTime = '00:00';
  }

  // Raw values from hardware
  const rawTemp = device01Live?.temperature || 0.0;
  const compVoltage = device01Live?.compensatedVoltage || 0.0;
  const phVoltage = device02Live?.voltage || device01Live?.phVoltage || 0.0;

  // Calibrated values
  const finalTemp = Number(calculateTemp(rawTemp, tempCal).toFixed(2));
  const finalTDS = Number(calculateTDS(compVoltage, tdsCal).toFixed(1));
  const finalPH = Number(calculatePH(phVoltage, phCal).toFixed(2));

  const snapshot = {
    timestamp: now.getTime(),
    yearMonth: `${year}-${month}`,
    date: `${year}-${month}-${day}`,
    time: `${String(hour).padStart(2, '0')}:${minute}`,
    milestoneSlot: slotTime,
    milestoneName: milestone,
    temperature: finalTemp,
    tds: finalTDS,
    ph: finalPH,
    raw: {
      factoryTemp: rawTemp,
      compVoltage: compVoltage,
      phVoltage: phVoltage,
      rawADC: device01Live?.rawADC || 0,
      phADC: device02Live?.rawADC || 0,
    },
    relays: {
      '1': Boolean(device01Live?.relay1),
      '2': Boolean(device01Live?.relay2),
      '3': Boolean(device01Live?.relay3),
      '4': Boolean(device01Live?.relay4),
    },
    devicesOnline: {
      device01: Boolean(device01Live?.online),
      device02: Boolean(device02Live?.online),
    },
  };

  const key = `${year}-${month}-${day}_${slotTime.replace(':', '-')}`;
  const path = `/history/${year}-${month}/${key}.json`;

  console.log(`Writing milestone snapshot to: ${path}`);
  console.log(JSON.stringify(snapshot, null, 2));

  await putJson(path, snapshot);
  console.log('✅ Milestone snapshot successfully written to Firebase!');
}

runLogger().catch((err) => {
  console.error('Fatal logger error:', err);
  process.exit(1);
});
