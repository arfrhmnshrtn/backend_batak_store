import { BadRequestException } from '@nestjs/common';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import { randomUUID } from 'crypto';
import type { Request } from 'express';

export const UPLOAD_DIR = join(process.cwd(), 'uploads', 'katalog-menu');
export const UPLOAD_URL_PREFIX = '/uploads/katalog-menu';

// Allowed MIME types
const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

// Allowed extensions (mapped from MIME)
const MIME_TO_EXT: Record<string, string> = {
  'image/jpeg': '.jpg',
  'image/png': '.png',
  'image/webp': '.webp',
};

// File signatures (magic bytes) for real format validation
const FILE_SIGNATURES: Array<{ mime: string; bytes: number[]; offset?: number }> = [
  // JPEG: FF D8 FF
  { mime: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  { mime: 'image/png', bytes: [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a] },
  // WebP: RIFF....WEBP
  { mime: 'image/webp', bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 }, // RIFF header
];

/**
 * Validates file signature (magic bytes) against expected MIME type.
 * This prevents attackers from renaming non-image files (e.g. PDF) with image extension.
 */
export function validateFileSignature(buffer: Buffer, declaredMime: string): boolean {
  for (const sig of FILE_SIGNATURES) {
    if (sig.mime !== declaredMime) continue;

    const offset = sig.offset ?? 0;
    const slice = buffer.slice(offset, offset + sig.bytes.length);

    const matches = sig.bytes.every((byte, i) => slice[i] === byte);

    // WebP: also check bytes 8-11 === WEBP
    if (matches && declaredMime === 'image/webp') {
      const webpId = buffer.slice(8, 12).toString('ascii');
      return webpId === 'WEBP';
    }

    if (matches) return true;
  }
  return false;
}

/**
 * Ensures the upload directory exists (creates it on startup if necessary).
 */
export function ensureUploadDirExists(): void {
  if (!existsSync(UPLOAD_DIR)) {
    mkdirSync(UPLOAD_DIR, { recursive: true });
  }
}

export const multerKatalogStorage = diskStorage({
  destination: (_req: Request, _file: Express.Multer.File, callback) => {
    ensureUploadDirExists();
    callback(null, UPLOAD_DIR);
  },
  filename: (_req: Request, file: Express.Multer.File, callback) => {
    const mime = file.mimetype;
    const ext = MIME_TO_EXT[mime] ?? extname(file.originalname).toLowerCase();
    const uniqueName = `${randomUUID()}${ext}`;
    callback(null, uniqueName);
  },
});

export const multerFileFilter = (
  _req: Request,
  file: Express.Multer.File,
  callback: (error: Error | null, acceptFile: boolean) => void,
): void => {
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    callback(
      new BadRequestException(
        `Format file tidak didukung. Hanya JPEG, PNG, dan WebP yang diizinkan. Diterima: ${file.mimetype}`,
      ),
      false,
    );
    return;
  }
  callback(null, true);
};

export const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024; // 5 MB
