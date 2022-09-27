const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const MAX_PAGES = 10000
const downloadPath = '/Volumes/LaCie/freesound-crawler/downloads';
const metadataPath = '/Volumes/LaCie/freesound-crawler/metadata';

const downloadedIds = fs.readdirSync(downloadPath).map(downloadUrl => downloadUrl.split("__")[0]);

const logIn = async () => {
  const browser = await puppeteer.launch({ devtools: false, headless: true });
  const page = await browser.newPage();
  await page.setRequestInterception(true);
  page.on('request', (req) => (req.resourceType() == 'stylesheet' || req.resourceType() == 'font' || req.resourceType() == 'image') ? req.abort() : req.continue());

  await page.goto('https://freesound.org/home/login/?next=/');
  await page.evaluate(async () => {
    $("#id_username").val("andrus.asumets@gmail.com");
    $("#id_password").val("k!U9KvgBGhQA46WunARfqeU*AkkP-qKKQLKsH!XbrqVvYe776qnB.f@LT@eYPVpr");
    $('input[type=submit]')[1].click();
  });

  await page.waitForTimeout(3000);
  return page;
};

const getPaginationCount = async (page) => {
  await page.goto('https://freesound.org/browse/packs/?order=-num_downloads');
  const pagePaginationCount = await page.evaluate(async () => {
    const pagePaginationCount = parseInt($('.last-page a')[0].text);
    return pagePaginationCount;
  });

  return pagePaginationCount;
};

const loadPages = async (page, pagePaginationCount) => {
  let pageIndex = 0;

  while (pageIndex != pagePaginationCount && pageIndex < MAX_PAGES) {
    await page.goto(`https://freesound.org/browse/packs/?order=-num_downloads&page=${pageIndex + 1}#pack`);
    const { packUrlsPerPage } = await page.evaluate(async () => {
      const packUrlsPerPage = $('.pack_description h4 a')
        .map(i => $('.pack_description h4 a')[i].href)
      return { packUrlsPerPage }
    });

    await loadPacks(page, packUrlsPerPage);
    pageIndex = pageIndex + 1
    console.log({ pagePaginationCount, pageIndex });
  }
};

const loadPacks = async (page, packUrlsPerPage) => {
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

    await loadPack(page, packPaginationCount, packUrlsPerPage[packIndex]);
    packIndex = packIndex + 1
  }
};

const loadPack = async (page, packPaginationCount, packUrl) => {
  let packPaginationIndex = 1;

  while (packPaginationIndex != packPaginationCount) {
    const packPaginationUrl = `${packUrl}?page=${packPaginationIndex + 1}#sound`;
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

    await download(page, soundUrls);

    packPaginationIndex = packPaginationIndex + 1;
  }
};

const download = async (page, soundUrls) => {
  let soundIndex = 0;

  while (soundIndex != soundUrls.length) {
    const soundUrl = soundUrls[soundIndex];
    await page.goto(soundUrl);
    const { durationStr, tags, downloads, rating, numratingsStr } = await page.evaluate(async () => {
      const durationStr = $('#sound_information_box dd').toArray()[1].innerText;
      let downloads = $('#download_text a')[0].text;
      downloads = parseInt(downloads.split("Downloaded")[1].split(" ")[0])
      let rating = parseInt($('.current-rating')[0].style.width.split('%')[0]);
      const tags = $('.tags li a').toArray().map(a => a.text.replace(",", "")).join(",");
      const numratingsStr = $('.numratings')[0].innerText;
      return { durationStr, tags, downloads, rating, numratingsStr };
    });

    const downloadId = soundUrl.split("/")[soundUrl.split("/").length - 2];
    const canDownload = !downloadedIds.includes(downloadId);
    const minutes = parseInt(durationStr.split(':')[0]);
    const seconds = parseInt(durationStr.split(':')[1].split('.')[0]);
    const milliseconds = parseInt(durationStr.split(':')[1].split('.')[1]);
    const duration = (minutes * 60 * 1000) + (seconds * 1000) + milliseconds;
    const numratings = parseInt(numratingsStr.split('(')[1].split(')')[0]);

    if (canDownload) {
      await page._client.send('Page.setDownloadBehavior', { behavior: 'allow', downloadPath: downloadPath });
      await page.click('#download_button');
    }

    const separator = "|";
    const metadata = `duration:${duration}${separator}downloads:${downloads}${separator}rating:${rating}${separator}numratings:${numratings}${separator}tags:${tags.replace(separator, "")}`;
    console.log(downloadId, metadata);

    fs.writeFileSync(path.join(metadataPath, downloadId), metadata);
    soundIndex = soundIndex + 1;
  }
};

(async () => {
  const page = await logIn();
  const pagePaginationCount = await getPaginationCount(page);
  await loadPages(page, pagePaginationCount);
})();
