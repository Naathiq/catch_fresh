// Helper to populate realistic demo milestone history for UI testing
const baseUrl = 'https://fish-9705a-default-rtdb.firebaseio.com';

async function seed() {
  const dates = ['2026-10-15', '2026-10-16', '2026-10-17', '2026-10-18', '2026-10-19'];
  const slots = [
    { time: '06:00', name: 'Morning', tOffset: -1.5, pOffset: -0.2, tdsOffset: -5 },
    { time: '12:00', name: 'Midday',  tOffset: 2.0,  pOffset: 0.3,  tdsOffset: 8 },
    { time: '18:00', name: 'Evening', tOffset: 0.8,  pOffset: 0.1,  tdsOffset: 2 },
    { time: '00:00', name: 'Midnight',tOffset: -1.0, pOffset: -0.1, tdsOffset: -3 }
  ];

  for (const date of dates) {
    for (const s of slots) {
      const key = `${date}_${s.time.replace(':', '-')}`;
      const temp = Number((27.5 + s.tOffset + (Math.random() * 0.4 - 0.2)).toFixed(2));
      const tds = Number((215.0 + s.tdsOffset + (Math.random() * 6 - 3)).toFixed(1));
      const ph = Number((7.6 + s.pOffset + (Math.random() * 0.2 - 0.1)).toFixed(2));
      const data = {
        date,
        time: s.time,
        milestoneSlot: s.time,
        milestoneName: s.name,
        temperature: temp,
        tds: tds,
        ph: ph,
        devicesOnline: { device01: true, device02: true },
        relays: { '1': true, '2': s.name === 'Morning' || s.name === 'Midday', '3': s.name === 'Midnight', '4': false },
        yearMonth: '2026-10',
        timestamp: new Date(`${date}T${s.time}:00+05:30`).getTime()
      };
      await fetch(`${baseUrl}/history/2026-10/${key}.json`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      console.log('Seeded:', key);
    }
  }
  console.log('✅ Done seeding demo history!');
}

seed();
