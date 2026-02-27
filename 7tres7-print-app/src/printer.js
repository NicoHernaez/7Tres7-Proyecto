const { execFile } = require('child_process');
const fs = require('fs');
const path = require('path');
const os = require('os');

let iconv;
try {
  iconv = require('iconv-lite');
} catch (e) {
  iconv = null;
}

// =============================================
// ESC/POS Constants
// =============================================
const ESC = 0x1B;
const GS = 0x1D;

const CMD = {
  INIT: Buffer.from([ESC, 0x40]),                    // Inicializar impresora
  CODEPAGE_PC858: Buffer.from([ESC, 0x74, 19]),      // Codepage 858 (Latin + Euro)
  CODEPAGE_PC850: Buffer.from([ESC, 0x74, 2]),       // Codepage 850 (Latin)
  ALIGN_LEFT: Buffer.from([ESC, 0x61, 0x00]),
  ALIGN_CENTER: Buffer.from([ESC, 0x61, 0x01]),
  ALIGN_RIGHT: Buffer.from([ESC, 0x61, 0x02]),
  FONT_NORMAL: Buffer.from([ESC, 0x21, 0x00]),
  FONT_BOLD: Buffer.from([ESC, 0x21, 0x08]),
  FONT_DOUBLE_HEIGHT: Buffer.from([ESC, 0x21, 0x10]),
  FONT_DOUBLE_WIDTH: Buffer.from([ESC, 0x21, 0x20]),
  FONT_BIG: Buffer.from([ESC, 0x21, 0x30]),          // Double width + height
  FONT_BIG_BOLD: Buffer.from([ESC, 0x21, 0x38]),     // Double w+h + bold
  CUT: Buffer.from([GS, 0x56, 0x00]),                // Corte total
  CUT_PARTIAL: Buffer.from([GS, 0x56, 0x01]),        // Corte parcial
  FEED_3: Buffer.from([0x0A, 0x0A, 0x0A]),           // 3 lineas
  FEED_5: Buffer.from([0x0A, 0x0A, 0x0A, 0x0A, 0x0A]),
};

// =============================================
// Encode text to CP858 (Spanish support)
// =============================================
function encodeText(str) {
  if (iconv) {
    return iconv.encode(str, 'cp858');
  }
  // Fallback: mapeo manual de caracteres comunes en espanol
  const CP858_MAP = {
    '\u00e1': 0xA0, // a
    '\u00e9': 0x82, // e
    '\u00ed': 0xA1, // i
    '\u00f3': 0xA2, // o
    '\u00fa': 0xA3, // u
    '\u00f1': 0xA4, // n
    '\u00d1': 0xA5, // N
    '\u00bf': 0xA8, // ?invertida
    '\u00a1': 0xAD, // !invertida
    '\u00fc': 0x81, // u dieresis
    '\u00c1': 0xB5, // A
    '\u00c9': 0x90, // E
    '\u00cd': 0xD6, // I
    '\u00d3': 0xE0, // O
    '\u00da': 0xE9, // U
  };
  const buf = [];
  for (const ch of str) {
    const code = ch.charCodeAt(0);
    if (CP858_MAP[ch]) {
      buf.push(CP858_MAP[ch]);
    } else if (code < 128) {
      buf.push(code);
    } else {
      buf.push(0x3F); // '?' para caracteres no mapeados
    }
  }
  return Buffer.from(buf);
}

// =============================================
// Ticket Builder (combina comandos + texto)
// =============================================
class TicketBuilder {
  constructor() {
    this.parts = [];
    // Inicializar + seleccionar codepage
    this.raw(CMD.INIT);
    this.raw(CMD.CODEPAGE_PC858);
  }

  raw(buf) {
    this.parts.push(buf);
    return this;
  }

  text(str) {
    this.parts.push(encodeText(str));
    return this;
  }

  line(str) {
    return this.text(str + '\n');
  }

  emptyLine() {
    this.parts.push(Buffer.from([0x0A]));
    return this;
  }

  separator(char = '-', width = 32) {
    return this.line(char.repeat(width));
  }

  doubleSeparator(width = 32) {
    return this.separator('=', width);
  }

  // Texto alineado a izquierda y derecha en la misma linea
  columns(left, right, width = 32) {
    const maxLeft = width - right.length - 1;
    const leftStr = left.length > maxLeft ? left.substring(0, maxLeft) : left;
    const padding = width - leftStr.length - right.length;
    return this.line(leftStr + ' '.repeat(Math.max(1, padding)) + right);
  }

  build() {
    return Buffer.concat(this.parts);
  }
}

// =============================================
// Generar comanda de cocina
// =============================================
function buildKitchenTicket(data) {
  const { orderNumber, tableOrDelivery, items } = data;
  const t = new TicketBuilder();

  // Header grande centrado
  t.raw(CMD.ALIGN_CENTER);
  t.raw(CMD.FONT_BIG_BOLD);
  t.line(`PEDIDO #${orderNumber}`);

  t.raw(CMD.FONT_DOUBLE_HEIGHT);
  t.line(tableOrDelivery || '');

  // Hora
  t.raw(CMD.FONT_NORMAL);
  t.line(new Date().toLocaleTimeString('es-AR', { hour: '2-digit', minute: '2-digit' }));

  t.raw(CMD.ALIGN_LEFT);
  t.separator();

  // Items
  for (const item of items) {
    t.raw(CMD.FONT_BIG_BOLD);
    t.line(`${item.quantity}x ${item.name}`);
    t.raw(CMD.FONT_NORMAL);

    if (item.cooking) {
      t.line(`   Coccion: ${item.cooking}`);
    }
    if (item.notes) {
      t.line(`   -> ${item.notes}`);
    }
  }

  t.separator();
  t.raw(CMD.ALIGN_CENTER);
  t.raw(CMD.FONT_NORMAL);
  t.line(new Date().toLocaleString('es-AR'));
  t.raw(CMD.FEED_3);
  t.raw(CMD.CUT);

  return t.build();
}

// =============================================
// Generar ticket completo (para Barra)
// =============================================
function buildFullTicket(order) {
  const t = new TicketBuilder();

  // Header
  t.raw(CMD.ALIGN_CENTER);
  t.raw(CMD.FONT_BIG_BOLD);
  t.line('7TRES7');
  t.raw(CMD.FONT_NORMAL);
  t.line('Restaurant & Delivery');
  t.line('Calle 18 N 737 - Gral. Pico');
  t.line('Tel: 2302 51-5656');
  t.doubleSeparator();

  // Info pedido
  t.raw(CMD.ALIGN_LEFT);
  t.raw(CMD.FONT_BOLD);
  t.line(`Pedido: #${order.orderNumber}`);
  t.raw(CMD.FONT_NORMAL);
  t.line(order.tableOrDelivery || '');
  t.line(`Fecha: ${new Date().toLocaleString('es-AR')}`);

  if (order.customerName) {
    t.line(`Cliente: ${order.customerName}`);
  }
  if (order.customerPhone) {
    t.line(`Tel: ${order.customerPhone}`);
  }

  t.separator();

  // Items
  for (const item of order.items) {
    const name = `${item.quantity}x ${item.name}`;
    const price = `$${formatNumber(item.subtotal || item.price * item.quantity)}`;
    t.columns(name, price);

    if (item.cooking) {
      t.line(`   ${item.cooking}`);
    }
    if (item.notes) {
      t.line(`   ${item.notes}`);
    }
  }

  t.separator();

  // Totales
  t.columns('Subtotal:', `$${formatNumber(order.subtotal)}`);

  if (order.discount > 0) {
    t.columns('Descuento:', `-$${formatNumber(order.discount)}`);
    if (order.discountReason) {
      t.line(`   (${order.discountReason})`);
    }
  }

  if (order.deliveryFee > 0) {
    t.columns('Envio:', `$${formatNumber(order.deliveryFee)}`);
  }

  t.doubleSeparator();
  t.raw(CMD.FONT_BIG_BOLD);
  t.columns('TOTAL:', `$${formatNumber(order.total)}`, 20);
  t.raw(CMD.FONT_NORMAL);
  t.line(`Pago: ${order.paymentMethod || 'Efectivo'}`);
  t.doubleSeparator();

  // Observaciones
  if (order.deliveryNotes) {
    t.raw(CMD.FONT_BOLD);
    t.line(`Notas: ${order.deliveryNotes}`);
    t.raw(CMD.FONT_NORMAL);
  }

  // Footer
  t.emptyLine();
  t.raw(CMD.ALIGN_CENTER);
  t.line('Gracias por tu compra!');
  t.line('Instagram: @737resto');
  t.raw(CMD.FEED_5);
  t.raw(CMD.CUT);

  return t.build();
}

// =============================================
// Generar ticket de prueba
// =============================================
function buildTestTicket(printerName) {
  const t = new TicketBuilder();

  t.raw(CMD.ALIGN_CENTER);
  t.raw(CMD.FONT_BIG_BOLD);
  t.line('7TRES7 PRINT');
  t.raw(CMD.FONT_NORMAL);
  t.doubleSeparator();
  t.line('PRUEBA DE IMPRESION');
  t.separator();
  t.line(`Impresora: ${printerName}`);
  t.line(`Fecha: ${new Date().toLocaleString('es-AR')}`);
  t.line(`PC: ${os.hostname()}`);
  t.separator();
  t.line('Caracteres especiales:');
  t.line('aeiou AEIOU');
  t.line('$1.234,56 - 10%');
  t.doubleSeparator();
  t.line('OK - Impresion exitosa');
  t.raw(CMD.FEED_3);
  t.raw(CMD.CUT);

  return t.build();
}

function formatNumber(num) {
  if (num == null) return '0';
  return Number(num).toLocaleString('es-AR');
}

// =============================================
// Enviar datos RAW a impresora Windows
// (PowerShell inline via -EncodedCommand, sin archivos .ps1)
// =============================================

// Construye el script PowerShell con WinAPI para imprimir raw bytes
function buildWinApiPrintScript(filePath, printerName) {
  const f = filePath.replace(/'/g, "''");
  const p = printerName.replace(/'/g, "''");
  // IMPORTANTE: "@ debe estar al inicio de linea (sin espacios antes)
  return `Add-Type @"
using System;
using System.IO;
using System.Runtime.InteropServices;
public class RawPrinterHelper {
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DOCINFOW {
        [MarshalAs(UnmanagedType.LPWStr)] public string pDocName;
        [MarshalAs(UnmanagedType.LPWStr)] public string pOutputFile;
        [MarshalAs(UnmanagedType.LPWStr)] public string pDataType;
    }
    [DllImport("winspool.drv", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool OpenPrinter(string szPrinter, out IntPtr hPrinter, IntPtr pd);
    [DllImport("winspool.drv", SetLastError = true)]
    public static extern bool ClosePrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool StartDocPrinter(IntPtr hPrinter, int level, ref DOCINFOW di);
    [DllImport("winspool.drv", SetLastError = true)]
    public static extern bool EndDocPrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", SetLastError = true)]
    public static extern bool StartPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", SetLastError = true)]
    public static extern bool EndPagePrinter(IntPtr hPrinter);
    [DllImport("winspool.drv", SetLastError = true)]
    public static extern bool WritePrinter(IntPtr hPrinter, IntPtr pBytes, int dwCount, out int dwWritten);
    public static bool SendRawData(string printerName, byte[] data) {
        IntPtr hPrinter;
        if (!OpenPrinter(printerName, out hPrinter, IntPtr.Zero)) {
            Console.Error.WriteLine("ERROR: No se pudo abrir impresora '" + printerName + "'. Cod: " + Marshal.GetLastWin32Error());
            return false;
        }
        DOCINFOW di = new DOCINFOW();
        di.pDocName = "7Tres7 Print Job";
        di.pDataType = "RAW";
        if (!StartDocPrinter(hPrinter, 1, ref di)) { ClosePrinter(hPrinter); return false; }
        if (!StartPagePrinter(hPrinter)) { EndDocPrinter(hPrinter); ClosePrinter(hPrinter); return false; }
        IntPtr pUnmanagedBytes = Marshal.AllocCoTaskMem(data.Length);
        Marshal.Copy(data, 0, pUnmanagedBytes, data.Length);
        int bytesWritten;
        bool ok = WritePrinter(hPrinter, pUnmanagedBytes, data.Length, out bytesWritten);
        Marshal.FreeCoTaskMem(pUnmanagedBytes);
        EndPagePrinter(hPrinter);
        EndDocPrinter(hPrinter);
        ClosePrinter(hPrinter);
        return ok;
    }
}
"@
if (-not (Test-Path '${f}')) { Write-Error "Archivo no encontrado: ${f}"; exit 1 }
` + "$bytes = [System.IO.File]::ReadAllBytes('" + f + "')\n" +
    "$result = [RawPrinterHelper]::SendRawData('" + p + "', $bytes)\n" +
    'if ($result) { Write-Output "OK"; exit 0 } else { Write-Error "FAIL"; exit 1 }';
}

function printRaw(printerName, dataBuffer) {
  return new Promise((resolve, reject) => {
    const tempFile = path.join(os.tmpdir(), `7t7_print_${Date.now()}.bin`);

    try {
      fs.writeFileSync(tempFile, dataBuffer);
    } catch (err) {
      return reject(new Error(`No se pudo escribir archivo temporal: ${err.message}`));
    }

    // Construir script inline y codificar como Base64 UTF-16LE
    const psScript = buildWinApiPrintScript(tempFile, printerName);
    const encoded = Buffer.from(psScript, 'utf16le').toString('base64');

    execFile('powershell.exe', [
      '-ExecutionPolicy', 'Bypass',
      '-NoProfile',
      '-NonInteractive',
      '-EncodedCommand', encoded,
    ], { timeout: 15000 }, (err, stdout, stderr) => {
      try { fs.unlinkSync(tempFile); } catch (e) { /* ignore */ }

      if (err) {
        // Fallback: copy /b a impresora compartida
        printRawFallback(printerName, dataBuffer)
          .then(resolve)
          .catch(() => reject(new Error(
            `Fallo al imprimir en "${printerName}": ${stderr || err.message}`
          )));
        return;
      }

      if (stdout.trim() === 'OK') {
        resolve();
      } else {
        reject(new Error(`Respuesta inesperada: ${stdout} ${stderr}`));
      }
    });
  });
}

function printRawFallback(printerName, dataBuffer) {
  return new Promise((resolve, reject) => {
    const tempFile = path.join(os.tmpdir(), `7t7_fb_${Date.now()}.bin`);

    try {
      fs.writeFileSync(tempFile, dataBuffer);
    } catch (err) {
      return reject(err);
    }

    const cmd = `copy /b "${tempFile}" "\\\\${os.hostname()}\\${printerName}"`;
    const { exec } = require('child_process');

    exec(cmd, { shell: 'cmd.exe', timeout: 10000 }, (err) => {
      try { fs.unlinkSync(tempFile); } catch (e) { /* ignore */ }
      if (err) reject(err);
      else resolve();
    });
  });
}

// =============================================
// API publica
// =============================================
async function printKitchenTicket(printerName, data) {
  const buffer = buildKitchenTicket(data);
  return printRaw(printerName, buffer);
}

async function printFullTicket(printerName, order) {
  const buffer = buildFullTicket(order);
  return printRaw(printerName, buffer);
}

async function printTestPage(printerName) {
  const buffer = buildTestTicket(printerName);
  return printRaw(printerName, buffer);
}

module.exports = {
  printKitchenTicket,
  printFullTicket,
  printTestPage,
  buildKitchenTicket,
  buildFullTicket,
};
