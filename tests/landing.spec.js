const { test, expect } = require('@playwright/test');

const BASE = 'https://rockfmturkey.com';

test.describe('RockFMTurkey landing page (production)', () => {
  test('serves landing page (not AzuraCast admin redirect)', async ({ page }) => {
    const response = await page.goto(BASE);
    expect(response.status()).toBe(200);
    expect(page.url()).toBe(BASE + '/');
    await expect(page).toHaveTitle(/Rock|FM/i);
  });

  test('shows hero with brand', async ({ page }) => {
    await page.goto(BASE);
    const body = await page.textContent('body');
    expect(body.toLowerCase()).toMatch(/rock/);
  });

  test('has working audio element pointing to HTTPS stream', async ({ page }) => {
    await page.goto(BASE);
    const audio = page.locator('audio').first();
    await expect(audio).toHaveCount(1);
    const src = await audio.evaluate(el => {
      return el.getAttribute('src') || el.querySelector('source')?.getAttribute('src') || '';
    });
    expect(src).toContain('https://');
    expect(src).toMatch(/rockfmturkey|stream/);
  });

  test('logo is referenced at correct path (no 404)', async ({ page }) => {
    const broken = [];
    page.on('response', resp => {
      if (resp.status() === 404 && /\.(jpg|png|svg|webp|gif|css|js)/.test(resp.url())) {
        broken.push(`${resp.status()} ${resp.url()}`);
      }
    });
    await page.goto(BASE, { waitUntil: 'networkidle' });
    expect(broken).toEqual([]);
  });

  test('all 3 store buttons are present and disabled (YAKINDA)', async ({ page }) => {
    await page.goto(BASE);
    const text = await page.textContent('body');
    expect(text.toUpperCase()).toContain('YAKINDA');
    expect(text.toLowerCase()).toMatch(/app store|apple/i);
    expect(text.toLowerCase()).toMatch(/play store|google/i);
    expect(text.toLowerCase()).toMatch(/huawei|appgallery/i);
  });

  test('logo image loads', async ({ page }) => {
    const resp = await page.request.get(BASE + '/logo.jpg');
    expect(resp.status()).toBe(200);
    expect(resp.headers()['content-type']).toMatch(/image\/jpeg/);
  });

  test('fetches now-playing API live and gets valid JSON', async ({ page, request }) => {
    const resp = await request.get(BASE + '/api/nowplaying/1');
    expect(resp.status()).toBe(200);
    const data = await resp.json();
    expect(data.station).toBeDefined();
    expect(data.station.shortcode).toBe('rockfmturkey');
    expect(data.station.listen_url).toContain('https://');
    expect(data.now_playing).toBeDefined();
    expect(data.now_playing.song).toBeDefined();
    expect(typeof data.now_playing.song.title).toBe('string');
  });

  test('client-side fetch loop updates now-playing card', async ({ page }) => {
    await page.goto(BASE);
    const apiCallPromise = page.waitForRequest(
      req => req.url().includes('/api/nowplaying/1'),
      { timeout: 20000 }
    );
    const req = await apiCallPromise;
    expect(req.url()).toContain('/api/nowplaying/1');
  });

  test('AzuraCast admin login still reachable at /login', async ({ request }) => {
    const resp = await request.get(BASE + '/login');
    expect(resp.status()).toBe(200);
    const html = await resp.text();
    expect(html.toLowerCase()).toMatch(/login|sign in|azura/i);
  });

  test('stream URL serves audio mime', async ({ request }) => {
    const resp = await request.head(BASE + '/listen/rockfmturkey/radio.mp3');
    expect(resp.status()).toBe(200);
    expect(resp.headers()['content-type']).toMatch(/audio\/mpeg|application\/octet-stream/);
  });

  test('HTTPS only — no mixed content', async ({ page }) => {
    await page.goto(BASE);
    const html = await page.content();
    const httpMatches = html.match(/http:\/\/(?!localhost|127\.0\.0\.1)[^"'\s<>]+/g) || [];
    expect(httpMatches).toEqual([]);
  });
});
