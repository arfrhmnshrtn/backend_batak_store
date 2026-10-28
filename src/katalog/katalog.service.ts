import {
  Injectable,
  NotFoundException,
  InternalServerErrorException,
  Logger,
  BadRequestException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateKatalogDto } from './dto/create-katalog.dto';
import { UpdateKatalogDto } from './dto/update-katalog.dto';
import {
  UPLOAD_DIR,
  UPLOAD_URL_PREFIX,
  ensureUploadDirExists,
  validateFileSignature,
} from './upload.config.js';
import { join } from 'path';
import { existsSync, unlinkSync, readFileSync } from 'fs';

@Injectable()
export class KatalogService {
  private readonly logger = new Logger(KatalogService.name);

  constructor(private readonly prisma: PrismaService) {
    ensureUploadDirExists();
  }

  /**
   * Checks if a given url_gambar value is a locally managed file path
   * (starts with the upload URL prefix) vs. an external URL or null.
   */
  private isLocalManagedFile(urlGambar: string | null | undefined): boolean {
    if (!urlGambar) return false;
    return urlGambar.startsWith(UPLOAD_URL_PREFIX + '/');
  }

  /**
   * Safely deletes a local upload file.
   * Only deletes files inside UPLOAD_DIR to prevent path traversal.
   * Logs a warning if deletion fails but does NOT throw.
   */
  private safeDeleteLocalFile(urlGambar: string): void {
    if (!this.isLocalManagedFile(urlGambar)) return;

    // Extract filename from path: /uploads/katalog-menu/<filename>
    const filename = urlGambar.slice(UPLOAD_URL_PREFIX.length + 1); // remove leading '/'

    // Security: ensure no path traversal
    if (filename.includes('..') || filename.includes('/') || filename.includes('\\')) {
      this.logger.warn(
        `Attempted path traversal detected in url_gambar: ${urlGambar}. Skipping deletion.`,
      );
      return;
    }

    const filePath = join(UPLOAD_DIR, filename);

    // Extra safety: make sure resolved path is still inside UPLOAD_DIR
    if (!filePath.startsWith(UPLOAD_DIR)) {
      this.logger.warn(
        `Resolved file path "${filePath}" is outside upload dir. Skipping deletion.`,
      );
      return;
    }

    if (!existsSync(filePath)) {
      this.logger.warn(`File not found during cleanup attempt: ${filePath}`);
      return;
    }

    try {
      unlinkSync(filePath);
      this.logger.log(`Deleted local file: ${filePath}`);
    } catch (err) {
      this.logger.warn(
        `Failed to delete local file: ${filePath}. Manual cleanup may be required. Error: ${String(err)}`,
      );
    }
  }

  /**
   * Validates uploaded file's magic bytes to confirm actual format.
   * Throws BadRequestException if file signature doesn't match MIME type.
   * Also deletes the temp/stored file on failure.
   */
  private validateAndCleanOnInvalidSignature(file: Express.Multer.File): void {
    const isValid = validateFileSignature(file.buffer ?? Buffer.alloc(0), file.mimetype);

    // When using diskStorage, file.buffer is undefined; we need to read the file
    if (!file.buffer) {
      // File already saved to disk via multer diskStorage.
      // We validate after saving; if invalid, delete immediately.
      const { readFileSync } = require('fs') as typeof import('fs');
      let buf: Buffer;
      try {
        buf = readFileSync(file.path);
      } catch {
        this.logger.warn(`Could not read uploaded file for signature validation: ${file.path}`);
        return; // Fail open: signature check not possible, proceed
      }

      const validOnDisk = validateFileSignature(buf, file.mimetype);
      if (!validOnDisk) {
        // Delete the bad file
        try {
          unlinkSync(file.path);
        } catch {
          // ignore
        }
        throw new BadRequestException(
          'File bukan gambar yang valid. Pastikan file adalah gambar JPEG, PNG, atau WebP asli.',
        );
      }
      return;
    }

    if (!isValid) {
      throw new BadRequestException(
        'File bukan gambar yang valid. Pastikan file adalah gambar JPEG, PNG, atau WebP asli.',
      );
    }
  }

  /**
   * Builds the URL path to store in DB from multer file info.
   * e.g. /uploads/katalog-menu/550e8400-uuid.jpg
   */
  private buildImagePath(file: Express.Multer.File): string {
    return `${UPLOAD_URL_PREFIX}/${file.filename}`;
  }

  async create(createKatalogDto: CreateKatalogDto, file?: Express.Multer.File) {
    let imagePath: string | undefined;

    if (file) {
      // Validate file signature (magic bytes) - deletes file and throws on failure
      this.validateAndCleanOnInvalidSignature(file);
      imagePath = this.buildImagePath(file);
    }

    let result;
    try {
      result = await this.prisma.katalog_menu.create({
        data: {
          ...createKatalogDto,
          url_gambar: imagePath ?? createKatalogDto.url_gambar,
        },
      });
    } catch (err) {
      // DB failed: clean up the uploaded file to avoid orphan files
      if (file && imagePath) {
        this.safeDeleteLocalFile(imagePath);
      }
      this.logger.error('Failed to create katalog_menu record:', err);
      throw new InternalServerErrorException('Gagal menyimpan menu ke database');
    }

    return result;
  }

  async findAll() {
    return this.prisma.katalog_menu.findMany({
      orderBy: { id: 'asc' },
    });
  }

  async findOne(id: number) {
    const item = await this.prisma.katalog_menu.findUnique({
      where: { id },
    });
    if (!item) {
      throw new NotFoundException(`Katalog menu dengan ID #${id} tidak ditemukan`);
    }
    return item;
  }

  async update(id: number, updateKatalogDto: UpdateKatalogDto, file?: Express.Multer.File) {
    const existing = await this.findOne(id);
    const oldImagePath = existing.url_gambar;

    let newImagePath: string | undefined;

    if (file) {
      // Validate signature; throws and deletes new file on failure
      this.validateAndCleanOnInvalidSignature(file);
      newImagePath = this.buildImagePath(file);
    }

    let updated;
    try {
      updated = await this.prisma.katalog_menu.update({
        where: { id },
        data: {
          ...updateKatalogDto,
          // Only override url_gambar if new file uploaded
          ...(newImagePath !== undefined && { url_gambar: newImagePath }),
        },
      });
    } catch (err) {
      // DB update failed: delete the newly uploaded file, keep old image
      if (file && newImagePath) {
        this.safeDeleteLocalFile(newImagePath);
      }
      this.logger.error(`Failed to update katalog_menu #${id}:`, err);
      throw new InternalServerErrorException('Gagal memperbarui data menu di database');
    }

    // DB update succeeded: safe to delete old local file
    if (newImagePath && oldImagePath) {
      this.safeDeleteLocalFile(oldImagePath);
    }

    return updated;
  }

  async remove(id: number) {
    const existing = await this.findOne(id);
    const imageToDelete = existing.url_gambar;

    let deleted;
    try {
      deleted = await this.prisma.katalog_menu.delete({
        where: { id },
      });
    } catch (err) {
      this.logger.error(`Failed to delete katalog_menu #${id}:`, err);
      throw new InternalServerErrorException('Gagal menghapus menu dari database');
    }

    // Delete local image only after DB delete succeeds
    if (imageToDelete) {
      this.safeDeleteLocalFile(imageToDelete);
    }

    return deleted;
  }
}
