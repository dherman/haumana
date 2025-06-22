# Openverse Image Downloader

A command-line tool to download images from Openverse with full metadata, including Creative Commons license information, photographer details, and high-resolution photographs.

## Features

- Downloads high-resolution images from Flickr (when available) or falls back to Openverse cached versions
- Extracts and preserves Creative Commons license information
- Saves photographer/creator names and photo titles
- Handles multiple source types (Flickr, Wikimedia Commons, etc.)
- Supports retrying failed downloads
- Organizes downloads with metadata in JSON format

## Installation

```bash
npm install
```

To install globally:

```bash
npm install -g .
```

## Usage

### Download Images

Download images from an input JSON file:

```bash
./openverse.js download images.json
```

Specify a custom output directory:

```bash
./openverse.js download images.json ./my-downloads
```

### Retry Failed Downloads

Retry any failed downloads from a previous run:

```bash
./openverse.js retry ./downloads
```

### Help

```bash
./openverse.js help
```

## Input Format

The input JSON file should have the following format:

```json
{
  "image-id-1": ["tag1", "tag2"],
  "image-id-2": ["tag3", "tag4"]
}
```

## Output Structure

The tool creates the following directory structure:

```
downloads/
├── summary.json
├── image-id-1/
│   ├── photo.jpg
│   └── metadata.json
├── image-id-2/
│   ├── photo.jpg
│   └── metadata.json
└── ...
```

### metadata.json

Each image directory contains a `metadata.json` file with:

- `id`: Openverse image ID
- `tags`: Tags from the input file
- `title`: Photo title
- `photographer`: Creator/photographer name
- `license`: Creative Commons license information with URL
- `sourceUrl`: Original source URL
- `flickrUrl`: Flickr URL (if applicable)
- `downloadedFrom`: Whether the image was downloaded from 'flickr' or 'openverse'
- `downloadedAt`: Timestamp of download

### summary.json

The summary file contains:

- Total image count
- Success/failure counts
- Download source statistics
- License information statistics
- Detailed results for each image

## Requirements

- Node.js 14 or higher
- npm

## Dependencies

- `puppeteer`: For browser automation to bypass Cloudflare protection
- `axios`: For HTTP requests
- `cheerio`: For HTML parsing
- `fs-extra`: For file system operations
- `ora`: for CLI status animations
- `cli-progress`: for CLI progress bar

## License

MIT
