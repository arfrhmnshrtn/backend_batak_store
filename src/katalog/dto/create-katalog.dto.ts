import { IsString, IsNotEmpty, IsNumber, IsEnum, IsOptional, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { kategori } from '@prisma/client';

export class CreateKatalogDto {
  @IsString()
  @IsNotEmpty()
  nama_item: string;

  @IsEnum(kategori)
  kategori: kategori;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  stok: number;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  harga_modal: number;

  @IsNumber()
  @Min(0)
  @Type(() => Number)
  harga_jual: number;

  /**
   * url_gambar bersifat opsional.
   * - Jika upload file baru: diisi otomatis oleh service dari path file yang tersimpan
   * - Jika tidak upload file: bisa dikosongkan (null/undefined)
   * - Untuk kompatibilitas data lama: jika frontend mengirim URL eksternal lama, nilai ini tetap disimpan
   */
  @IsOptional()
  @IsString()
  url_gambar?: string;
}
