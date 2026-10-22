-- CreateEnum
CREATE TYPE "user_role" AS ENUM ('OWNER', 'KASIR');

-- CreateEnum
CREATE TYPE "user_status" AS ENUM ('ACTIVE', 'INACTIVE');

-- CreateEnum
CREATE TYPE "status_pesanan" AS ENUM ('belum_bayar', 'lunas', 'hutang');

-- CreateEnum
CREATE TYPE "metode_pembayaran" AS ENUM ('tunai', 'qris', 'transfer');

-- CreateEnum
CREATE TYPE "jenis_transaksi" AS ENUM ('pemasukan', 'pengeluaran');

-- CreateEnum
CREATE TYPE "kategori" AS ENUM ('rokok', 'jajanan', 'minuman');

-- CreateEnum
CREATE TYPE "debt_type" AS ENUM ('CUSTOMER', 'SUPPLIER');

-- CreateEnum
CREATE TYPE "debt_status" AS ENUM ('BELUM_LUNAS', 'SEBAGIAN', 'LUNAS', 'DIBATALKAN');

-- CreateEnum
CREATE TYPE "waste_type" AS ENUM ('PRODUCT', 'INGREDIENT');

-- CreateEnum
CREATE TYPE "waste_reason" AS ENUM ('BASI', 'KADALUARSA', 'RUSAK', 'GOSONG', 'JATUH', 'SALAH_PRODUKSI', 'SISA_PRODUKSI', 'HILANG', 'LAINNYA');

-- CreateEnum
CREATE TYPE "stock_movement_type" AS ENUM ('IN', 'OUT', 'WASTE', 'ADJUSTMENT');

-- CreateEnum
CREATE TYPE "budget_type" AS ENUM ('PERCENTAGE', 'FIXED');

-- CreateTable
CREATE TABLE "user" (
    "id" SERIAL NOT NULL,
    "fullname" TEXT NOT NULL,
    "pin" TEXT NOT NULL,
    "role" "user_role" NOT NULL,
    "status" "user_status" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "deleted_at" TIMESTAMP(3),

    CONSTRAINT "user_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "permission" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_permission" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "permission_id" INTEGER NOT NULL,

    CONSTRAINT "user_permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "role_permission" (
    "id" SERIAL NOT NULL,
    "role" "user_role" NOT NULL,
    "permission_id" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "role_permission_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_token" (
    "id" SERIAL NOT NULL,
    "user_id" INTEGER NOT NULL,
    "token_hash" TEXT NOT NULL,
    "expired_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "refresh_token_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "katalog_menu" (
    "id" SERIAL NOT NULL,
    "nama_item" TEXT NOT NULL,
    "kategori" "kategori" NOT NULL,
    "stok" INTEGER NOT NULL,
    "harga_modal" INTEGER NOT NULL,
    "harga_jual" INTEGER NOT NULL,
    "url_gambar" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "katalog_menu_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pesanan" (
    "id" SERIAL NOT NULL,
    "nomor_pesanan" TEXT NOT NULL,
    "nama_pelanggan" TEXT,
    "total_item" INTEGER NOT NULL,
    "total_harga" INTEGER NOT NULL,
    "metode_pembayaran" "metode_pembayaran",
    "status" "status_pesanan" NOT NULL DEFAULT 'belum_bayar',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pesanan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "detail_pesanan" (
    "id" SERIAL NOT NULL,
    "id_pesanan" INTEGER NOT NULL,
    "id_menu" INTEGER NOT NULL,
    "nama_menu" TEXT NOT NULL,
    "harga" INTEGER NOT NULL,
    "harga_modal" INTEGER NOT NULL DEFAULT 0,
    "jumlah" INTEGER NOT NULL,
    "subtotal" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "detail_pesanan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kategori_keuangan" (
    "id" SERIAL NOT NULL,
    "nama" TEXT NOT NULL,
    "jenis" "jenis_transaksi" NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kategori_keuangan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "transaksi_keuangan" (
    "id" SERIAL NOT NULL,
    "nomor_transaksi" TEXT NOT NULL,
    "jenis" "jenis_transaksi" NOT NULL,
    "id_kategori" INTEGER NOT NULL,
    "nominal" INTEGER NOT NULL,
    "metode_pembayaran" "metode_pembayaran",
    "keterangan" TEXT NOT NULL,
    "id_pesanan" INTEGER,
    "id_user" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "transaksi_keuangan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pengeluaran_bahan_baku" (
    "id" SERIAL NOT NULL,
    "nama_item" TEXT NOT NULL,
    "jumlah" DOUBLE PRECISION NOT NULL,
    "satuan" TEXT NOT NULL,
    "harga_satuan" INTEGER NOT NULL,
    "total_harga" INTEGER NOT NULL,
    "catatan" TEXT,
    "id_transaksi_keuangan" INTEGER NOT NULL,
    "created_by" INTEGER NOT NULL,
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "pengeluaran_bahan_baku_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "debt" (
    "id" SERIAL NOT NULL,
    "type" "debt_type" NOT NULL,
    "customer_name" TEXT,
    "supplier_name" TEXT,
    "note" TEXT,
    "total_amount" INTEGER NOT NULL,
    "paid_amount" INTEGER NOT NULL DEFAULT 0,
    "remaining_amount" INTEGER NOT NULL,
    "status" "debt_status" NOT NULL DEFAULT 'BELUM_LUNAS',
    "id_pesanan" INTEGER,
    "created_by" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "debt_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "debt_payment" (
    "id" SERIAL NOT NULL,
    "id_debt" INTEGER NOT NULL,
    "amount" INTEGER NOT NULL,
    "payment_method" "metode_pembayaran" NOT NULL,
    "paid_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "id_user" INTEGER NOT NULL,
    "id_transaksi_keuangan" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "debt_payment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ingredient" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "unit" TEXT NOT NULL,
    "cost_per_unit" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ingredient_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "waste" (
    "id" SERIAL NOT NULL,
    "type" "waste_type" NOT NULL,
    "id_katalog_menu" INTEGER,
    "id_ingredient" INTEGER,
    "quantity" INTEGER NOT NULL,
    "unit" TEXT NOT NULL,
    "cost_per_unit" INTEGER NOT NULL,
    "total_loss" INTEGER NOT NULL,
    "reason" "waste_reason" NOT NULL,
    "note" TEXT,
    "created_by" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "waste_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "stock_movement" (
    "id" SERIAL NOT NULL,
    "type" "stock_movement_type" NOT NULL,
    "id_katalog_menu" INTEGER,
    "id_ingredient" INTEGER,
    "quantity" INTEGER NOT NULL,
    "stock_before" INTEGER NOT NULL,
    "stock_after" INTEGER NOT NULL,
    "reference_type" TEXT,
    "reference_id" INTEGER,
    "id_waste" INTEGER,
    "created_by" INTEGER,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "stock_movement_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "cash_balance" (
    "id" SERIAL NOT NULL,
    "payment_method" "metode_pembayaran" NOT NULL,
    "amount" INTEGER NOT NULL,
    "effective_date" DATE NOT NULL,
    "created_by" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "cash_balance_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "budget_allocation" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "allocation_type" "budget_type" NOT NULL DEFAULT 'PERCENTAGE',
    "percentage" INTEGER NOT NULL DEFAULT 0,
    "fixed_amount" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "description" TEXT,
    "created_by" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "budget_allocation_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "user_role_idx" ON "user"("role");

-- CreateIndex
CREATE INDEX "user_status_idx" ON "user"("status");

-- CreateIndex
CREATE INDEX "user_deleted_at_idx" ON "user"("deleted_at");

-- CreateIndex
CREATE UNIQUE INDEX "permission_name_key" ON "permission"("name");

-- CreateIndex
CREATE INDEX "user_permission_user_id_idx" ON "user_permission"("user_id");

-- CreateIndex
CREATE INDEX "user_permission_permission_id_idx" ON "user_permission"("permission_id");

-- CreateIndex
CREATE UNIQUE INDEX "user_permission_user_id_permission_id_key" ON "user_permission"("user_id", "permission_id");

-- CreateIndex
CREATE INDEX "role_permission_role_idx" ON "role_permission"("role");

-- CreateIndex
CREATE INDEX "role_permission_permission_id_idx" ON "role_permission"("permission_id");

-- CreateIndex
CREATE UNIQUE INDEX "role_permission_role_permission_id_key" ON "role_permission"("role", "permission_id");

-- CreateIndex
CREATE INDEX "refresh_token_user_id_idx" ON "refresh_token"("user_id");

-- CreateIndex
CREATE INDEX "refresh_token_expired_at_idx" ON "refresh_token"("expired_at");

-- CreateIndex
CREATE UNIQUE INDEX "pesanan_nomor_pesanan_key" ON "pesanan"("nomor_pesanan");

-- CreateIndex
CREATE INDEX "pesanan_status_created_at_idx" ON "pesanan"("status", "created_at");

-- CreateIndex
CREATE INDEX "pesanan_created_at_idx" ON "pesanan"("created_at");

-- CreateIndex
CREATE INDEX "detail_pesanan_id_pesanan_idx" ON "detail_pesanan"("id_pesanan");

-- CreateIndex
CREATE UNIQUE INDEX "kategori_keuangan_nama_key" ON "kategori_keuangan"("nama");

-- CreateIndex
CREATE UNIQUE INDEX "transaksi_keuangan_nomor_transaksi_key" ON "transaksi_keuangan"("nomor_transaksi");

-- CreateIndex
CREATE UNIQUE INDEX "pengeluaran_bahan_baku_id_transaksi_keuangan_key" ON "pengeluaran_bahan_baku"("id_transaksi_keuangan");

-- CreateIndex
CREATE INDEX "pengeluaran_bahan_baku_created_by_idx" ON "pengeluaran_bahan_baku"("created_by");

-- CreateIndex
CREATE INDEX "pengeluaran_bahan_baku_tanggal_idx" ON "pengeluaran_bahan_baku"("tanggal");

-- CreateIndex
CREATE UNIQUE INDEX "debt_id_pesanan_key" ON "debt"("id_pesanan");

-- CreateIndex
CREATE UNIQUE INDEX "debt_payment_id_transaksi_keuangan_key" ON "debt_payment"("id_transaksi_keuangan");

-- CreateIndex
CREATE INDEX "debt_payment_paid_at_idx" ON "debt_payment"("paid_at");

-- CreateIndex
CREATE INDEX "debt_payment_id_debt_idx" ON "debt_payment"("id_debt");

-- CreateIndex
CREATE INDEX "waste_type_idx" ON "waste"("type");

-- CreateIndex
CREATE INDEX "waste_reason_idx" ON "waste"("reason");

-- CreateIndex
CREATE INDEX "waste_created_by_idx" ON "waste"("created_by");

-- CreateIndex
CREATE INDEX "waste_created_at_idx" ON "waste"("created_at");

-- CreateIndex
CREATE INDEX "stock_movement_type_idx" ON "stock_movement"("type");

-- CreateIndex
CREATE INDEX "stock_movement_created_at_idx" ON "stock_movement"("created_at");

-- CreateIndex
CREATE UNIQUE INDEX "cash_balance_payment_method_effective_date_key" ON "cash_balance"("payment_method", "effective_date");

-- AddForeignKey
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_permission" ADD CONSTRAINT "user_permission_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permission"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "role_permission" ADD CONSTRAINT "role_permission_permission_id_fkey" FOREIGN KEY ("permission_id") REFERENCES "permission"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_token" ADD CONSTRAINT "refresh_token_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "user"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "detail_pesanan" ADD CONSTRAINT "detail_pesanan_id_pesanan_fkey" FOREIGN KEY ("id_pesanan") REFERENCES "pesanan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "detail_pesanan" ADD CONSTRAINT "detail_pesanan_id_menu_fkey" FOREIGN KEY ("id_menu") REFERENCES "katalog_menu"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaksi_keuangan" ADD CONSTRAINT "transaksi_keuangan_id_kategori_fkey" FOREIGN KEY ("id_kategori") REFERENCES "kategori_keuangan"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaksi_keuangan" ADD CONSTRAINT "transaksi_keuangan_id_pesanan_fkey" FOREIGN KEY ("id_pesanan") REFERENCES "pesanan"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "transaksi_keuangan" ADD CONSTRAINT "transaksi_keuangan_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pengeluaran_bahan_baku" ADD CONSTRAINT "pengeluaran_bahan_baku_id_transaksi_keuangan_fkey" FOREIGN KEY ("id_transaksi_keuangan") REFERENCES "transaksi_keuangan"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pengeluaran_bahan_baku" ADD CONSTRAINT "pengeluaran_bahan_baku_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "debt" ADD CONSTRAINT "debt_id_pesanan_fkey" FOREIGN KEY ("id_pesanan") REFERENCES "pesanan"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "debt" ADD CONSTRAINT "debt_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "debt_payment" ADD CONSTRAINT "debt_payment_id_debt_fkey" FOREIGN KEY ("id_debt") REFERENCES "debt"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "debt_payment" ADD CONSTRAINT "debt_payment_id_user_fkey" FOREIGN KEY ("id_user") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "debt_payment" ADD CONSTRAINT "debt_payment_id_transaksi_keuangan_fkey" FOREIGN KEY ("id_transaksi_keuangan") REFERENCES "transaksi_keuangan"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "waste" ADD CONSTRAINT "waste_id_katalog_menu_fkey" FOREIGN KEY ("id_katalog_menu") REFERENCES "katalog_menu"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "waste" ADD CONSTRAINT "waste_id_ingredient_fkey" FOREIGN KEY ("id_ingredient") REFERENCES "ingredient"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "waste" ADD CONSTRAINT "waste_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movement" ADD CONSTRAINT "stock_movement_id_katalog_menu_fkey" FOREIGN KEY ("id_katalog_menu") REFERENCES "katalog_menu"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movement" ADD CONSTRAINT "stock_movement_id_ingredient_fkey" FOREIGN KEY ("id_ingredient") REFERENCES "ingredient"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movement" ADD CONSTRAINT "stock_movement_id_waste_fkey" FOREIGN KEY ("id_waste") REFERENCES "waste"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "stock_movement" ADD CONSTRAINT "stock_movement_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "cash_balance" ADD CONSTRAINT "cash_balance_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "budget_allocation" ADD CONSTRAINT "budget_allocation_created_by_fkey" FOREIGN KEY ("created_by") REFERENCES "user"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
