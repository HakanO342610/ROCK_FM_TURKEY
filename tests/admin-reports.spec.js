const { test } = require('@playwright/test');
const API_KEY = 'd84556d2697c9496:bcf179cf1921cfaa0f74d66718035818';

test('web admin reports tab visible', async ({ browser }) => {
  const ctx = await browser.newContext({ viewport: { width: 1280, height: 1600 } });
  const page = await ctx.newPage();
  await page.goto('https://rockfmturkey.com/admin/', { waitUntil: 'networkidle' });
  await page.fill('#apiKeyInput', API_KEY);
  await page.click('#loginBtn');
  await page.waitForSelector('#listenerChart', { timeout: 10000 });
  await page.waitForTimeout(3000);
  await page.screenshot({ path: '/tmp/admin-reports.png', fullPage: true });
  const has = await page.evaluate(() => {
    return {
      raporlar: !!document.querySelector('.section-title') && [...document.querySelectorAll('.section-title')].some(s => s.textContent.includes('RAPORLAR')),
      chart: !!document.querySelector('#listenerChart'),
      topSongs: document.querySelectorAll('#topSongsList .top-row').length,
      recent: document.querySelectorAll('#recentList .recent-row').length,
      statNums: [...document.querySelectorAll('.stat-num')].map(s => s.textContent),
    };
  });
  console.log(JSON.stringify(has, null, 2));
});
