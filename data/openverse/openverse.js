#!/usr/bin/env node

import fs from 'fs-extra';
import axios from 'axios';
import * as cheerio from 'cheerio';
import path from 'path';
import puppeteer from 'puppeteer';
import ora from 'ora';

const USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
const VIEWPORT_SIZE = { width: 1920, height: 1080 };

// Parse command line arguments
const args = process.argv.slice(2);
const command = args[0];

function showHelp() {
  console.log(`
Openverse Image Downloader - Download images from Openverse with full metadata and licenses

Usage:
  openverse download <input.json> [output-dir]
  openverse retry <output-dir>
  openverse help

Commands:
  download    Download images from an input JSON file
              - input.json: JSON file with Openverse image IDs (required)
              - output-dir: Output directory (default: ./downloads)
              
  retry       Retry failed downloads from a previous run
              - output-dir: Directory with previous download results (required)
              
Examples:
  openverse download images.json
  openverse download images.json ./my-images
  openverse retry ./downloads
`);
}

// Helper function to fetch Openverse page with Puppeteer
async function fetchOpenversePage(browser, imageId) {
  const url = `https://openverse.org/image/${imageId}`;
  
  const page = await browser.newPage();
  
  try {
    await page.setViewport(VIEWPORT_SIZE);
    await page.setUserAgent(USER_AGENT);
    
    await page.goto(url, { 
      waitUntil: 'networkidle2',
      timeout: 30000 
    });
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    const pageData = await page.evaluate(() => {
      // Get the "Get this image" button link
      let sourceUrl = null;
      const links = Array.from(document.querySelectorAll('a'));
      for (const link of links) {
        if (link.textContent && link.textContent.includes('Get this image')) {
          sourceUrl = link.href;
          break;
        }
      }
      
      // Get the main image URL from Openverse
      let openverseImageUrl = null;
      const mainImage = document.querySelector('img#main-image, img.main-photo, img[alt]');
      if (mainImage) {
        openverseImageUrl = mainImage.src;
      }
      
      // Get title from the page
      let title = null;
      const h1 = document.querySelector('h1');
      if (h1) {
        title = h1.textContent.trim();
      }
      
      // Extract creator and source from the page
      let creator = null;
      let source = null;
      
      const buttons = Array.from(document.querySelectorAll('a.group\\/button'));
      for (const button of buttons) {
        const svgUse = button.querySelector('svg use');
        if (svgUse) {
          const href = svgUse.getAttribute('href');
          if (href && href.includes('person')) {
            creator = button.textContent.trim();
          } else if (href && href.includes('institution')) {
            source = button.textContent.trim();
          }
        }
      }
      
      // Extract license information from Openverse page
      let license = null;
      let licenseUrl = null;
      
      const ccLinks = Array.from(document.querySelectorAll('a[href*="creativecommons.org/licenses"]'));
      if (ccLinks.length > 0) {
        licenseUrl = ccLinks[0].href;
        license = ccLinks[0].textContent.trim();
      }
      
      return { sourceUrl, openverseImageUrl, title, creator, source, license, licenseUrl };
    });
    
    await page.close();
    
    return pageData;
  } catch (error) {
    // Error handled silently
    await page.close();
    return null;
  }
}

// Helper function to extract Flickr URL from Wikimedia
async function extractFlickrUrlFromWikimedia(wikimediaUrl) {
  try {
    const response = await axios.get(wikimediaUrl, {
      headers: {
        'User-Agent': USER_AGENT
      }
    });
    
    const $ = cheerio.load(response.data);
    
    // Look for Flickr links
    let flickrUrl = null;
    
    const flickrLinks = $('a[href*="flickr.com/photos/"]');
    if (flickrLinks.length > 0) {
      flickrUrl = flickrLinks.first().attr('href');
    }
    
    if (!flickrUrl) {
      $('td').each((i, el) => {
        const $el = $(el);
        const text = $el.text();
        if (text.includes('Source')) {
          const $nextTd = $el.next('td');
          const $link = $nextTd.find('a[href*="flickr.com/photos/"]').first();
          if ($link.length > 0) {
            flickrUrl = $link.attr('href');
          }
        }
      });
    }
    
    if (!flickrUrl) {
      const metadataText = $('body').text();
      const flickrMatch = metadataText.match(/https?:\/\/(?:www\.)?flickr\.com\/photos\/[^\s"'<>]+/);
      if (flickrMatch) {
        flickrUrl = flickrMatch[0];
      }
    }
    
    // Extract license info from Wikimedia
    let license = null;
    let licenseUrl = null;
    
    const ccLinks = $('a[href*="creativecommons.org/licenses"]');
    if (ccLinks.length > 0) {
      licenseUrl = ccLinks.first().attr('href');
      const match = licenseUrl.match(/creativecommons\.org\/licenses\/([\w-]+)\/([\d.]+)/);
      if (match) {
        license = `CC ${match[1].toUpperCase()} ${match[2]}`;
      }
    }
    
    return { flickrUrl, license, licenseUrl };
  } catch (error) {
    // Error handled silently
    return { flickrUrl: null, license: null, licenseUrl: null };
  }
}

// Helper function to fetch Flickr photo data
async function fetchFlickrPhotoData(browser, flickrUrl) {
  const page = await browser.newPage();
  
  try {
    await page.setViewport(VIEWPORT_SIZE);
    await page.setUserAgent(USER_AGENT);
    
    await page.goto(flickrUrl, {
      waitUntil: 'networkidle2',
      timeout: 30000
    });
    
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // Extract photo data
    const photoData = await page.evaluate(() => {
      // Extract photographer name
      let photographer = 'Unknown';
      const ownerLink = document.querySelector('a.owner-name, a[data-track="owner"], a.attribution-info');
      if (ownerLink) {
        photographer = ownerLink.textContent.trim();
      }
      
      // Extract photo title
      let title = 'Untitled';
      const titleElement = document.querySelector('h1.photo-title, h1[data-testid="photo-title"], h1.view-title-info-title');
      if (titleElement) {
        title = titleElement.textContent.trim();
      }
      
      // Extract license info
      let licenseText = null;
      let licenseUrl = null;
      
      const licenseSelectors = [
        'a[href*="creativecommons.org/licenses"]',
        'a.photo-license-url',
        'a[rel="license"]',
        '.photo-license-info a',
        '.view-license-info a'
      ];
      
      for (const selector of licenseSelectors) {
        const licenseLink = document.querySelector(selector);
        if (licenseLink && licenseLink.href.includes('creativecommons.org')) {
          licenseUrl = licenseLink.href;
          licenseText = licenseLink.textContent.trim();
          
          if (!licenseText.startsWith('CC')) {
            const match = licenseUrl.match(/creativecommons\.org\/licenses\/([\w-]+)\/([\d.]+)/);
            if (match) {
              licenseText = `CC ${match[1].toUpperCase()} ${match[2]}`;
            }
          }
          break;
        }
      }
      
      // Check for "Some rights reserved" text
      if (!licenseUrl) {
        const rightsElements = Array.from(document.querySelectorAll('span, div'));
        for (const el of rightsElements) {
          if (el.textContent.includes('Some rights reserved')) {
            const nearbyLink = el.parentElement.querySelector('a[href*="creativecommons.org"]');
            if (nearbyLink) {
              licenseUrl = nearbyLink.href;
              const match = licenseUrl.match(/creativecommons\.org\/licenses\/([\w-]+)\/([\d.]+)/);
              if (match) {
                licenseText = `CC ${match[1].toUpperCase()} ${match[2]}`;
              }
            }
          }
        }
      }
      
      return { photographer, title, licenseText, licenseUrl };
    });
    
    // Try to get the highest resolution image
    let imageUrl = null;
    
    try {
      const sizesButton = await page.$('a[href*="/sizes/"], a:has-text("View all sizes"), a:has-text("All sizes")');
      if (sizesButton) {
        await sizesButton.click();
        await page.waitForNavigation({ waitUntil: 'networkidle2' });
        await new Promise(resolve => setTimeout(resolve, 1000));
        
        const originalLink = await page.$('a:has-text("Original")');
        if (originalLink) {
          await originalLink.click();
          await page.waitForNavigation({ waitUntil: 'networkidle2' });
          
          imageUrl = await page.evaluate(() => {
            const img = document.querySelector('img#allsizes-photo, img.main-photo');
            return img ? img.src : null;
          });
        }
      }
    } catch (e) {
      // Could not navigate to sizes page, trying alternative method
    }
    
    // Fallback: get the largest available image from the current page
    if (!imageUrl) {
      imageUrl = await page.evaluate(() => {
        const images = Array.from(document.querySelectorAll('img'));
        let largestImg = null;
        let largestSize = 0;
        
        for (const img of images) {
          if (img.src && img.src.includes('live.staticflickr.com')) {
            const width = parseInt(img.getAttribute('width') || '0');
            const height = parseInt(img.getAttribute('height') || '0');
            const size = width * height;
            
            if (size > largestSize) {
              largestSize = size;
              largestImg = img;
            }
          }
        }
        
        if (largestImg) {
          let src = largestImg.src;
          src = src.replace(/_[a-z]\.(jpg|png|gif)$/i, '_o.$1');
          return src;
        }
        
        return null;
      });
    }
    
    await page.close();
    
    return {
      title: photoData.title,
      photographer: photoData.photographer,
      license: {
        text: photoData.licenseText,
        url: photoData.licenseUrl
      },
      imageUrl,
      flickrUrl
    };
  } catch (error) {
    // Error handled silently
    await page.close();
    return null;
  }
}

// Helper function to download image
async function downloadImage(imageUrl, filepath, referer = 'https://www.flickr.com/') {
  const tempPath = `${filepath}.tmp`;
  
  try {
    const response = await axios.get(imageUrl, { 
      responseType: 'stream',
      headers: {
        'User-Agent': USER_AGENT,
        'Referer': referer
      }
    });
    
    // Write to temporary file first
    const writer = fs.createWriteStream(tempPath);
    
    response.data.pipe(writer);
    
    await new Promise((resolve, reject) => {
      writer.on('finish', resolve);
      writer.on('error', reject);
    });
    
    // Move temporary file to final location
    await fs.move(tempPath, filepath, { overwrite: true });
    
  } catch (error) {
    // Clean up temporary file if it exists
    try {
      await fs.remove(tempPath);
    } catch (cleanupError) {
      // Ignore cleanup errors
    }
    
    // Error handled silently
    throw error;
  }
}

// Main function to process a single image
async function processImage(browser, imageId, tags, outputDir, spinner = null) {
  const updateStatus = (message) => {
    if (spinner && spinner.isSpinning) {
      spinner.text = message;
    }
    // Don't log anything if no spinner
  };
  
  // Get data from Openverse
  updateStatus(`Processing ${imageId} (fetching from Openverse)...`);
  const openverseData = await fetchOpenversePage(browser, imageId);
  if (!openverseData) {
    return null;
  }
  
  const { 
    sourceUrl, 
    openverseImageUrl, 
    title: openverseTitle, 
    creator: openverseCreator, 
    source: openverseSource,
    license: openverseLicense,
    licenseUrl: openverseLicenseUrl
  } = openverseData;
  
  // Try to get Flickr data if available
  let flickrUrl = null;
  let photoData = null;
  let wikimediaLicense = null;
  let wikimediaLicenseUrl = null;
  let useOpenverseFallback = false;
  
  if (sourceUrl) {
    if (sourceUrl.includes('flickr.com')) {
      flickrUrl = sourceUrl;
      updateStatus(`Processing ${imageId} (found direct Flickr source)...`);
    } else if (sourceUrl.includes('wikimedia.org') || sourceUrl.includes('commons.wikimedia.org')) {
      updateStatus(`Processing ${imageId} (checking Wikimedia Commons)...`);
      const wikimediaData = await extractFlickrUrlFromWikimedia(sourceUrl);
      flickrUrl = wikimediaData.flickrUrl;
      wikimediaLicense = wikimediaData.license;
      wikimediaLicenseUrl = wikimediaData.licenseUrl;
    }
    
    if (flickrUrl) {
      updateStatus(`Processing ${imageId} (fetching Flickr metadata)...`);
      photoData = await fetchFlickrPhotoData(browser, flickrUrl);
    }
  }
  
  // Create directory for this image
  const imageDir = path.join(outputDir, imageId);
  await fs.ensureDir(imageDir);
  
  // Download the image
  let downloaded = false;
  let imageExtension = '.jpg';
  const imagePath = path.join(imageDir, `photo${imageExtension}`);
  
  // Try Flickr first if we have photo data
  if (photoData && photoData.imageUrl) {
    updateStatus(`Processing ${imageId} (downloading from Flickr)...`);
    
    try {
      await downloadImage(photoData.imageUrl, imagePath);
      downloaded = true;
    } catch (error) {
      // Try different resolutions
      const resolutionSuffixes = ['_b', '_c', '_z', '_n', '_m'];
      
      for (const suffix of resolutionSuffixes) {
        let altUrl = photoData.imageUrl;
        
        if (altUrl.match(/_[a-z]\.(jpg|png|gif)$/i)) {
          altUrl = altUrl.replace(/_[a-z]\.(jpg|png|gif)$/i, `${suffix}.$1`);
        } else if (altUrl.match(/\.(jpg|png|gif)$/i)) {
          altUrl = altUrl.replace(/\.(jpg|png|gif)$/i, `${suffix}.$1`);
        }
        
        updateStatus(`Processing ${imageId} (trying ${suffix} resolution)...`);
        
        try {
          await downloadImage(altUrl, imagePath);
          downloaded = true;
          break;
        } catch (altError) {
          // Continue to next resolution
        }
      }
    }
  }
  
  // If Flickr download failed, try Openverse
  if (!downloaded && openverseImageUrl) {
    updateStatus(`Processing ${imageId} (downloading from Openverse fallback)...`);
    useOpenverseFallback = true;
    
    try {
      const urlExtension = path.extname(openverseImageUrl.split('?')[0]);
      if (urlExtension) {
        imageExtension = urlExtension;
        const newImagePath = path.join(imageDir, `photo${imageExtension}`);
        await downloadImage(openverseImageUrl, newImagePath, 'https://openverse.org/');
        downloaded = true;
      } else {
        await downloadImage(openverseImageUrl, imagePath, 'https://openverse.org/');
        downloaded = true;
      }
    } catch (error) {
      // Failed to download from Openverse
    }
  }
  
  if (!downloaded) {
    return null;
  }
  
  // Determine final license info
  let finalLicense = null;
  let finalLicenseUrl = null;
  
  if (photoData && photoData.license.url) {
    finalLicense = photoData.license.text;
    finalLicenseUrl = photoData.license.url;
  } else if (wikimediaLicenseUrl) {
    finalLicense = wikimediaLicense;
    finalLicenseUrl = wikimediaLicenseUrl;
  } else if (openverseLicenseUrl) {
    finalLicense = openverseLicense;
    finalLicenseUrl = openverseLicenseUrl;
  }
  
  // Save metadata
  const metadata = {
    id: imageId,
    tags: tags,
    openverseUrl: `https://openverse.org/image/${imageId}`,
    sourceUrl: sourceUrl || null,
    flickrUrl: flickrUrl || null,
    title: (photoData && photoData.title) || openverseTitle || null,
    photographer: (photoData && photoData.photographer) || openverseCreator || null,
    source: openverseSource || null,
    license: {
      text: finalLicense,
      url: finalLicenseUrl
    },
    downloadedAt: new Date().toISOString(),
    originalImageUrl: (photoData && photoData.imageUrl) || openverseImageUrl || null,
    downloadedFrom: useOpenverseFallback ? 'openverse' : 'flickr',
    localImagePath: `photo${imageExtension}`
  };
  
  updateStatus(`Processing ${imageId} (saving metadata)...`);
  const metadataPath = path.join(imageDir, 'metadata.json');
  await fs.writeJson(metadataPath, metadata, { spaces: 2 });
  
  updateStatus(`Processing ${imageId} (complete)...`);
  return metadata;
}

// Main download function
async function download(inputFile, outputDir = './downloads') {
  // Check if output directory exists and is non-empty
  if (await fs.pathExists(outputDir)) {
    const files = await fs.readdir(outputDir);
    if (files.length > 0) {
      console.error(`Error: Output directory '${outputDir}' already exists and is not empty.`);
      console.error('Please specify a different directory or remove the existing one.');
      process.exit(1);
    }
  }
  
  // Read input file
  let images;
  try {
    images = await fs.readJson(inputFile);
  } catch (error) {
    console.error(`Error reading input file '${inputFile}':`, error.message);
    process.exit(1);
  }
    
  // Create output directory
  await fs.ensureDir(outputDir);
  
  let browser;
  
  try {
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const results = [];
    const imageEntries = Object.entries(images);
    
    console.log(`\nFound ${imageEntries.length} images to process\n`);
    
    let successCount = 0;
    let failCount = 0;
    
    // Create spinner for status line
    const statusSpinner = ora({
      stream: process.stdout,
      discardStdin: false
    });
    
    // Function to render progress
    const renderProgress = (current, total) => {
      const percentage = Math.floor((current / total) * 100);
      const barLength = 30;
      const filled = Math.floor((current / total) * barLength);
      const bar = '█'.repeat(filled) + '░'.repeat(barLength - filled);
      
      // Move cursor to beginning of line and clear
      process.stdout.write('\r\x1B[2K');
      process.stdout.write(`Progress |${bar}| ${percentage}% | ${current}/${total} Images | ${successCount} succeeded, ${failCount} failed`);
    };
    
    // Initial progress bar
    renderProgress(0, imageEntries.length);
    console.log(); // Move to next line for spinner
    
    for (let i = 0; i < imageEntries.length; i++) {
      const [imageId, tags] = imageEntries[i];
      
      // Start spinner for current file
      statusSpinner.start(`Processing ${imageId}...`);
      
      const result = await processImage(browser, imageId, tags, outputDir, statusSpinner);
      
      if (result) {
        successCount++;
      } else {
        failCount++;
      }
      
      results.push({ imageId, tags, success: !!result, metadata: result });
      
      // Stop spinner
      statusSpinner.stop();
      
      // Move cursor up 1 line to progress bar line
      process.stdout.write('\x1B[1A');
      
      // Update progress
      renderProgress(i + 1, imageEntries.length);
      
      // Move back down to spinner line
      console.log();
      
      // Add a delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 1000));
    }
    
    console.log(); // Add newline after progress
    
    // Save summary
    const summary = {
      totalImages: imageEntries.length,
      successful: results.filter(r => r.success).length,
      failed: results.filter(r => !r.success).length,
      downloadedFromFlickr: results.filter(r => r.metadata && r.metadata.downloadedFrom === 'flickr').length,
      downloadedFromOpenverse: results.filter(r => r.metadata && r.metadata.downloadedFrom === 'openverse').length,
      withLicense: results.filter(r => r.metadata && r.metadata.license && r.metadata.license.url).length,
      results: results
    };
    
    await fs.writeJson(path.join(outputDir, 'summary.json'), summary, { spaces: 2 });
    
    console.log('\n=== Summary ===');
    console.log(`Total images: ${summary.totalImages}`);
    console.log(`Successfully downloaded: ${summary.successful}`);
    console.log(`  - From Flickr: ${summary.downloadedFromFlickr}`);
    console.log(`  - From Openverse: ${summary.downloadedFromOpenverse}`);
    console.log(`  - With license info: ${summary.withLicense}`);
    console.log(`Failed: ${summary.failed}`);
    
  } catch (error) {
    console.error('Error:', error);
    if (browser) {
      await browser.close();
    }
    process.exit(1);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
  
  // Ensure process exits
  process.exit(0);
}

// Retry function
async function retry(outputDir) {
  // Check if directory exists and has summary.json
  const summaryPath = path.join(outputDir, 'summary.json');
  if (!await fs.pathExists(summaryPath)) {
    console.error(`Error: No summary.json found in '${outputDir}'.`);
    console.error('This directory does not appear to contain results from a previous download.');
    process.exit(1);
  }
  
  // Load existing summary
  const existingSummary = await fs.readJson(summaryPath);
  
  // Find failed images
  const failedResults = existingSummary.results.filter(r => !r.success);
  
  if (failedResults.length === 0) {
    console.log('No failed images to retry. All images were successfully downloaded.');
    process.exit(0);
  }
  
  console.log(`Found ${failedResults.length} failed images to retry.\n`);
  
  let browser;
  
  try {
    browser = await puppeteer.launch({
      headless: 'new',
      args: ['--no-sandbox', '--disable-setuid-sandbox']
    });
    
    const retryResults = [];
    
    let successCount = 0;
    let failCount = 0;
    
    // Create spinner for status line
    const statusSpinner = ora({
      stream: process.stdout,
      discardStdin: false
    });
    
    // Function to render progress
    const renderProgress = (current, total) => {
      const percentage = Math.floor((current / total) * 100);
      const barLength = 30;
      const filled = Math.floor((current / total) * barLength);
      const bar = '█'.repeat(filled) + '░'.repeat(barLength - filled);
      
      // Move cursor to beginning of line and clear
      process.stdout.write('\r\x1B[2K');
      process.stdout.write(`Retry Progress |${bar}| ${percentage}% | ${current}/${total} Images | ${successCount} succeeded, ${failCount} still failed`);
    };
    
    // Initial progress bar
    renderProgress(0, failedResults.length);
    console.log(); // Move to next line for spinner
    
    for (let i = 0; i < failedResults.length; i++) {
      const { imageId, tags } = failedResults[i];
      
      // Start spinner for current file
      statusSpinner.start(`Retrying ${imageId}...`);
      
      const result = await processImage(browser, imageId, tags, outputDir, statusSpinner);
      
      if (result) {
        successCount++;
      } else {
        failCount++;
      }
      
      retryResults.push({ imageId, tags, success: !!result, metadata: result });
      
      // Update the existing summary
      const existingIndex = existingSummary.results.findIndex(r => r.imageId === imageId);
      if (existingIndex >= 0) {
        existingSummary.results[existingIndex] = { imageId, tags, success: !!result, metadata: result };
      }
      
      // Stop spinner
      statusSpinner.stop();
      
      // Move cursor up 1 line to progress bar line
      process.stdout.write('\x1B[1A');
      
      // Update progress
      renderProgress(i + 1, failedResults.length);
      
      // Move back down to spinner line
      console.log();
      
      // Add a delay to avoid rate limiting
      await new Promise(resolve => setTimeout(resolve, 2000));
    }
    
    // Show cursor again
    process.stdout.write('\x1B[?25h');
    console.log('\n'); // Add newlines after progress
    
    // Recalculate totals
    existingSummary.successful = existingSummary.results.filter(r => r.success).length;
    existingSummary.failed = existingSummary.results.filter(r => !r.success).length;
    existingSummary.downloadedFromFlickr = existingSummary.results.filter(r => r.metadata && r.metadata.downloadedFrom === 'flickr').length;
    existingSummary.downloadedFromOpenverse = existingSummary.results.filter(r => r.metadata && r.metadata.downloadedFrom === 'openverse').length;
    existingSummary.withLicense = existingSummary.results.filter(r => r.metadata && r.metadata.license && r.metadata.license.url).length;
    
    // Save updated summary
    await fs.writeJson(summaryPath, existingSummary, { spaces: 2 });
    
    console.log('\n=== Retry Summary ===');
    console.log(`Images retried: ${retryResults.length}`);
    console.log(`Newly successful: ${retryResults.filter(r => r.success).length}`);
    console.log(`Still failed: ${retryResults.filter(r => !r.success).length}`);
    
    console.log('\n=== Overall Summary ===');
    console.log(`Total images: ${existingSummary.totalImages}`);
    console.log(`Successfully downloaded: ${existingSummary.successful}`);
    console.log(`  - From Flickr: ${existingSummary.downloadedFromFlickr}`);
    console.log(`  - From Openverse: ${existingSummary.downloadedFromOpenverse}`);
    console.log(`  - With license info: ${existingSummary.withLicense}`);
    console.log(`Failed: ${existingSummary.failed}`);
    
  } catch (error) {
    console.error('Error:', error);
    if (browser) {
      await browser.close();
    }
    process.exit(1);
  } finally {
    if (browser) {
      await browser.close();
    }
  }
  
  // Ensure process exits
  process.exit(0);
}

// Main CLI handler
async function main() {
  if (args.length === 0 || command === 'help' || command === '--help' || command === '-h') {
    showHelp();
    process.exit(0);
  }
  
  switch (command) {
    case 'download':
      if (args.length < 2) {
        console.error('Error: Input JSON file is required.');
        console.error('Usage: openverse-downloader download <input.json> [output-dir]');
        process.exit(1);
      }
      await download(args[1], args[2]);
      break;
      
    case 'retry':
      if (args.length < 2) {
        console.error('Error: Output directory is required.');
        console.error('Usage: openverse-downloader retry <output-dir>');
        process.exit(1);
      }
      await retry(args[1]);
      break;
      
    default:
      console.error(`Unknown command: ${command}`);
      showHelp();
      process.exit(1);
  }
}

// Run the CLI
main().catch(error => {
  console.error('Unexpected error:', error);
  process.exit(1);
});