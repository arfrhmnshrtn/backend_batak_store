import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { KatalogService } from './katalog.service';
import { CreateKatalogDto } from './dto/create-katalog.dto';
import { UpdateKatalogDto } from './dto/update-katalog.dto';
import {
  multerKatalogStorage,
  multerFileFilter,
  MAX_FILE_SIZE_BYTES,
} from './upload.config';

@Controller('katalog')
export class KatalogController {
  constructor(private readonly katalogService: KatalogService) {}

  @Post()
  @UseInterceptors(
    FileInterceptor('foto', {
      storage: multerKatalogStorage,
      fileFilter: multerFileFilter,
      limits: {
        fileSize: MAX_FILE_SIZE_BYTES,
      },
    }),
  )
  create(
    @Body() createKatalogDto: CreateKatalogDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file && file.size > MAX_FILE_SIZE_BYTES) {
      throw new BadRequestException(
        `Ukuran file terlalu besar. Maksimum ${MAX_FILE_SIZE_BYTES / (1024 * 1024)} MB.`,
      );
    }
    return this.katalogService.create(createKatalogDto, file);
  }

  @Get()
  findAll() {
    return this.katalogService.findAll();
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.katalogService.findOne(+id);
  }

  @Patch(':id')
  @UseInterceptors(
    FileInterceptor('foto', {
      storage: multerKatalogStorage,
      fileFilter: multerFileFilter,
      limits: {
        fileSize: MAX_FILE_SIZE_BYTES,
      },
    }),
  )
  update(
    @Param('id') id: string,
    @Body() updateKatalogDto: UpdateKatalogDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    if (file && file.size > MAX_FILE_SIZE_BYTES) {
      throw new BadRequestException(
        `Ukuran file terlalu besar. Maksimum ${MAX_FILE_SIZE_BYTES / (1024 * 1024)} MB.`,
      );
    }
    return this.katalogService.update(+id, updateKatalogDto, file);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.katalogService.remove(+id);
  }
}
