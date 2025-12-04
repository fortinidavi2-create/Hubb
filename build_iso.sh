#!/bin/bash
set -e

# Diret\u00f3rios
HUBB_DIR="/workspaces/Hubb"
ROOTFS="$HUBB_DIR/rootfs"
BUILD="$HUBB_DIR/build"
KERNEL_BUILD="$BUILD/linux-6.6.1"
BASH_BUILD="$BUILD/bash-5.2.21"

echo "[*] Aguardando compila\u00e7\u00e3o do kernel..."
# Aguardar kernel compilar
while [ ! -f "$KERNEL_BUILD/arch/x86_64/boot/bzImage" ]; do
    sleep 5
    echo -n "."
done
echo ""
echo "[+] Kernel compilado!"

# Copiar kernel para o rootfs
echo "[*] Copiando kernel para rootfs..."
cp "$KERNEL_BUILD/arch/x86_64/boot/bzImage" "$ROOTFS/boot/vmlinuz-6.6.1"

# Instalar Bash no rootfs
echo "[*] Instalando Bash no rootfs..."
mkdir -p "$ROOTFS/bin"
cp "$BASH_BUILD/bash" "$ROOTFS/bin/bash"
chmod +x "$ROOTFS/bin/bash"
ln -sf bash "$ROOTFS/bin/sh"

# Copiar bibliotecas essenciais
echo "[*] Copiando bibliotecas essenciais..."
mkdir -p "$ROOTFS/lib64"
mkdir -p "$ROOTFS/usr/lib"

# Copiar libc e outras libs essenciais
ldd "$BASH_BUILD/bash" | grep "=>" | awk '{print $3}' | while read lib; do
    if [ -f "$lib" ] && [ -n "$lib" ]; then
        cp "$lib" "$ROOTFS/lib64/" 2>/dev/null || true
    fi
done

# Copiar ld-linux
cp /lib64/ld-linux-x86-64.so.2 "$ROOTFS/lib64/" 2>/dev/null || true

# Criar init script m\u00ednimo
echo "[*] Criando init script..."
cat > "$ROOTFS/init" << 'EOF'
#!/bin/bash
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /tmp

clear
echo "========================================"
echo "       Bem-vindo ao HubbOS"
echo "Linux Kernel 6.6.1 + Bash 5.2.21"
echo "========================================"
echo ""
/bin/bash
EOF
chmod +x "$ROOTFS/init"

# Criar \u00e1rvore de diret\u00f3rios adicionais
echo "[*] Criando estrutura de diret\u00f3rios..."
mkdir -p "$ROOTFS/"{mnt,root,run,srv,opt,var/{log,tmp}}

# Criar arquivo /etc/fstab m\u00ednimo
echo "[*] Criando configura\u00e7\u00f5es m\u00ednimas..."
cat > "$ROOTFS/etc/fstab" << 'EOF'
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devtmpfs /dev devtmpfs defaults 0 0
EOF

# Criar passwd e group m\u00ednimos
cat > "$ROOTFS/etc/passwd" << 'EOF'
root:x:0:0:root:/root:/bin/bash
EOF

cat > "$ROOTFS/etc/group" << 'EOF'
root:x:0:
EOF

# Criar grub.cfg para boot
echo "[*] Criando configura\u00e7\u00e3o do GRUB..."
mkdir -p "$ROOTFS/boot/grub"
cat > "$ROOTFS/boot/grub/grub.cfg" << 'EOF'
menuentry "HubbOS" {
    insmod gzio
    insmod part_msdos
    insmod ext2
    set root='(hd0,msdos1)'
    linux /boot/vmlinuz-6.6.1 root=/dev/sda1 ro quiet
}
EOF

echo "[+] Rootfs preparado!"
echo "[*] Gerando ISO..."

# Gerar ISO
cd "$HUBB_DIR"
xorriso -as mkisofs \
    -b isolinux.bin \
    -c boot.cat \
    -no-emul-boot \
    -boot-load-size 4 \
    -boot-info-table \
    -R -J \
    -o "HubbOS.iso" \
    "$ROOTFS" 2>&1 || true

# Se xorriso falhar, tentar com grub
if [ ! -f "$HUBB_DIR/HubbOS.iso" ]; then
    echo "[*] Tentando criar ISO com GRUB..."
    
    # Preparar estrutura GRUB
    mkdir -p "$ROOTFS/boot/grub/i386-pc"
    
    # Usar grub-mkrescue se dispon\u00edvel
    grub-mkrescue -o "$HUBB_DIR/HubbOS.iso" "$ROOTFS" 2>/dev/null || \
    mkisofs -R -b boot/grub/stage2_eltorito \
            -no-emul-boot -boot-load-size 4 \
            -boot-info-table \
            -o "$HUBB_DIR/HubbOS.iso" "$ROOTFS" || true
fi

if [ -f "$HUBB_DIR/HubbOS.iso" ]; then
    echo "[+] ISO criada com sucesso!"
    ls -lh "$HUBB_DIR/HubbOS.iso"
else
    echo "[!] Erro ao criar ISO"
    exit 1
fi
