const {chromium} = require('/Users/lotte/local-business/tasks/daily-games-20261123-0500/roof-breath-run/node_modules/playwright');
(async()=>{
  const browser = await chromium.launch({headless:true, executablePath:'/Applications/Google Chrome.app/Contents/MacOS/Google Chrome', args:['--enable-webgl','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
  for(const [name,viewport] of [['desktop',{width:1280,height:800}],['mobile',{width:320,height:700}]]) {
    const page = await browser.newPage({viewport, deviceScaleFactor:1, hasTouch:name==='mobile', isMobile:name==='mobile'});
    const tap = (x,y)=>name==='mobile' ? page.touchscreen.tap(x,y) : page.mouse.click(x,y);
    const failures = [];
    page.on('console', m=>console.log(name,'console',m.type(),m.text()));
    page.on('pageerror', e=>{console.log(name,'pageerror',e.message);failures.push(e.message)});
    await page.goto('http://127.0.0.1:8877/index.html');
    await page.waitForTimeout(6000);
    console.log(name,await page.title(),await page.locator('canvas').count());
    if(await page.title() !== '이중 궤도 신호원' || await page.locator('canvas').count() !== 1) throw new Error('Godot canvas/title missing');
    await page.screenshot({path:`../../artifacts/a1-screenshots/${name}-menu.png`,timeout:15000});
    await tap(viewport.width/2,viewport.height-90);
    await page.waitForTimeout(300);
    await page.screenshot({path:`../../artifacts/a1-screenshots/${name}-tutorial.png`,timeout:15000});
    await tap(viewport.width/2,viewport.height-90);
    await page.waitForTimeout(400);
    await page.screenshot({path:`../../artifacts/a1-screenshots/${name}-playing.png`,timeout:15000});
    await tap(viewport.width-47,42);
    await page.waitForTimeout(150);
    await page.screenshot({path:`../../artifacts/a1-screenshots/${name}-paused.png`,timeout:15000});
    await page.keyboard.press('Escape');
    await page.keyboard.press('KeyR');
    if(name === 'mobile') await tap(viewport.width/2,viewport.height-90);
    else await page.keyboard.press('Space');
    await page.waitForTimeout(8000);
    await page.screenshot({path:`../../artifacts/a1-screenshots/${name}-game-over.png`,timeout:15000});
    if(failures.length) throw new Error(failures.join('; '));
    await page.close();
  }
  await browser.close();
})().catch(e=>{console.error(e);process.exit(1)});
