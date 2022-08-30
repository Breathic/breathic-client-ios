const puppeteer = require("puppeteer");

(async () => {
  const MAX_PAGES = 10000

  const browser = await puppeteer.launch({ devtools: false });
  const page = await browser.newPage();
  await page.goto('https://freesound.org/home/login/?next=/');
  await page.evaluate(async () => {
    $("#id_username").val("andrus.asumets@gmail.com");
    $("#id_password").val("k!U9KvgBGhQA46WunARfqeU*AkkP-qKKQLKsH!XbrqVvYe776qnB.f@LT@eYPVpr");
    $('input[type=submit]')[1].click();
  });

  await page.waitForTimeout(3000);

  await page.goto('https://freesound.org/browse/packs/?order=-num_downloads');
  const pagePaginationCount = await page.evaluate(async () => {
    const pagePaginationCount = parseInt($('.last-page a')[0].text);
    return pagePaginationCount;
  });

  let pageIndex = 603;
  while (pageIndex != pagePaginationCount && pageIndex < MAX_PAGES) {
    await page.goto(`https://freesound.org/browse/packs/?order=-num_downloads&page=${pageIndex + 1}#pack`);
    const { packUrlsPerPage } = await page.evaluate(async () => {
      const packUrlsPerPage = $('.pack_description h4 a')
        .map(i => $('.pack_description h4 a')[i].href)
      return { packUrlsPerPage }
    });

    let packIndex = 0
    while (packIndex != packUrlsPerPage.length) {
      await page.goto(packUrlsPerPage[packIndex]);
      const { packPaginationCount } = await page.evaluate(async () => {
      const packPaginationCount = $('.other-page').length / 2 + 1;
        const hasSamples = $("img[src$='/media/images/licenses/nolaw.png']").length > 0;
        if (!hasSamples) {
          return { packPaginationCount: 0 }
        }

        return { packPaginationCount } ;
      });

      if (packPaginationCount == 0) {
        packIndex = packIndex + 1;
        continue;
      }
      
      let packPaginationIndex = 1;
      while (packPaginationIndex != packPaginationCount) {
        const packPaginationUrl = `${packUrlsPerPage[packIndex]}?page=${packPaginationIndex + 1}#sound`;
        await page.goto(packPaginationUrl);
        const { soundUrls } = await page.evaluate(async () => {
          const nolawIds = $('.cc_license').toArray().map(img => {
            if (img.src.includes("nolaw")) {
              const parent = $(img).parent("div").parent("div").parent("div");
              const nolawId  = $(parent)['0'].id;
              return nolawId;
            }
          }).filter(nolawId => nolawId);
          
          const soundUrls = $('.sample_player_small').toArray().map(player => {
            const playerId = $(player).context.id;
            const url = $("#" + playerId).find(".title")[0].href;
            return nolawIds.includes(playerId) ? url : null;
          }).filter(nolawId => nolawId);

          return { soundUrls };
        });

        let soundIndex = 0;
        while (soundIndex != soundUrls.length) {
          const soundUrl = soundUrls[soundIndex];
          await page.goto(soundUrl);
          await page._client.send('Page.setDownloadBehavior', { behavior: 'allow', downloadPath: '/Volumes/LaCie/freesound-crawler/downloads' });
          await page.click('#download_button');
          soundIndex = soundIndex + 1;
        }
        
        packPaginationIndex = packPaginationIndex + 1;
      }

      packIndex = packIndex + 1
    }

    pageIndex = pageIndex + 1

    console.log({ pagePaginationCount, pageIndex });
  }
})();