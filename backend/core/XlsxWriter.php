<?php
declare(strict_types=1);

/**
 * Generador mínimo de archivos .xlsx (OOXML) sin dependencias externas.
 * Requiere extensión PHP zip.
 */
class XlsxWriter
{
    /** @var list<array{name: string, rows: list<list<scalar|null>>, bold_rows: list<int>}> */
    private array $sheets = [];

    /**
     * @param list<list<scalar|null>> $rows
     * @param list<int> $boldRows Índices de fila 1-based a renderizar en negrita
     */
    public function addSheet(string $name, array $rows, array $boldRows = []): void
    {
        $safeName = $name !== '' ? $name : 'Hoja' . (count($this->sheets) + 1);
        if (strlen($safeName) > 31) {
            $safeName = substr($safeName, 0, 31);
        }

        $this->sheets[] = [
            'name' => $safeName,
            'rows' => $rows,
            'bold_rows' => $boldRows,
        ];
    }

    public function output(string $filename): never
    {
        if ($this->sheets === []) {
            throw new InvalidArgumentException('No hay hojas para exportar.');
        }

        if (!class_exists(ZipArchive::class)) {
            throw new RuntimeException('La extensión PHP zip no está disponible.');
        }

        $tmp = tempnam(sys_get_temp_dir(), 'xlsx_');
        if ($tmp === false) {
            throw new RuntimeException('No se pudo crear archivo temporal.');
        }

        $zip = new ZipArchive();
        if ($zip->open($tmp, ZipArchive::OVERWRITE) !== true) {
            @unlink($tmp);
            throw new RuntimeException('No se pudo crear el archivo Excel.');
        }

        $zip->addFromString('[Content_Types].xml', $this->contentTypesXml());
        $zip->addFromString('_rels/.rels', $this->rootRelsXml());
        $zip->addFromString('xl/_rels/workbook.xml.rels', $this->workbookRelsXml());
        $zip->addFromString('xl/workbook.xml', $this->workbookXml());
        $zip->addFromString('xl/styles.xml', $this->stylesXml());

        foreach ($this->sheets as $index => $sheet) {
            $sheetNum = $index + 1;
            $zip->addFromString(
                'xl/worksheets/sheet' . $sheetNum . '.xml',
                $this->worksheetXml($sheet['rows'], $sheet['bold_rows'])
            );
        }

        $zip->close();

        $safeFilename = preg_replace('/[^\w\-\.]/', '_', $filename) ?: 'export.xlsx';
        if (!str_ends_with(strtolower($safeFilename), '.xlsx')) {
            $safeFilename .= '.xlsx';
        }

        header('Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        header('Content-Disposition: attachment; filename="' . $safeFilename . '"');
        header('Cache-Control: max-age=0');
        header('Content-Length: ' . (string) filesize($tmp));

        readfile($tmp);
        @unlink($tmp);
        exit;
    }

    private function contentTypesXml(): string
    {
        $overrides = '';
        foreach ($this->sheets as $index => $sheet) {
            $sheetNum = $index + 1;
            $overrides .= '<Override PartName="/xl/worksheets/sheet' . $sheetNum . '.xml"'
                . ' ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>';
        }

        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            . '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            . '<Default Extension="xml" ContentType="application/xml"/>'
            . '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            . '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
            . $overrides
            . '</Types>';
    }

    private function rootRelsXml(): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            . '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
            . '</Relationships>';
    }

    private function workbookRelsXml(): string
    {
        $rels = '';
        foreach ($this->sheets as $index => $sheet) {
            $sheetNum = $index + 1;
            $rels .= '<Relationship Id="rId' . $sheetNum . '"'
                . ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet"'
                . ' Target="worksheets/sheet' . $sheetNum . '.xml"/>';
        }
        $styleId = count($this->sheets) + 1;

        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            . $rels
            . '<Relationship Id="rId' . $styleId . '"'
            . ' Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles"'
            . ' Target="styles.xml"/>'
            . '</Relationships>';
    }

    private function workbookXml(): string
    {
        $sheetsXml = '';
        foreach ($this->sheets as $index => $sheet) {
            $sheetNum = $index + 1;
            $name = htmlspecialchars($sheet['name'], ENT_XML1 | ENT_QUOTES, 'UTF-8');
            $sheetsXml .= '<sheet name="' . $name . '" sheetId="' . $sheetNum . '" r:id="rId' . $sheetNum . '"/>';
        }

        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"'
            . ' xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            . '<sheets>' . $sheetsXml . '</sheets>'
            . '</workbook>';
    }

    private function stylesXml(): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            . '<fonts count="2">'
            . '<font><sz val="11"/><name val="Calibri"/></font>'
            . '<font><b/><sz val="11"/><name val="Calibri"/></font>'
            . '</fonts>'
            . '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>'
            . '<borders count="1"><border/></borders>'
            . '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
            . '<cellXfs count="2">'
            . '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
            . '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
            . '</cellXfs>'
            . '</styleSheet>';
    }

    /**
     * @param list<list<scalar|null>> $rows
     * @param list<int> $boldRows
     */
    private function worksheetXml(array $rows, array $boldRows): string
    {
        $boldLookup = array_flip($boldRows);
        $rowsXml = '';

        foreach ($rows as $rowIndex => $cells) {
            $rowNum = $rowIndex + 1;
            $style = isset($boldLookup[$rowNum]) ? ' s="1"' : '';
            $cellsXml = '';

            foreach (array_values($cells) as $colIndex => $value) {
                $colLetter = $this->columnLetter($colIndex + 1);
                $ref = $colLetter . $rowNum;
                $cellsXml .= $this->cellXml($ref, $value, $style);
            }

            $rowsXml .= '<row r="' . $rowNum . '">' . $cellsXml . '</row>';
        }

        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            . '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            . '<sheetData>' . $rowsXml . '</sheetData>'
            . '</worksheet>';
    }

    private function cellXml(string $ref, mixed $value, string $styleAttr): string
    {
        if ($value === null || $value === '') {
            return '<c r="' . $ref . '"' . $styleAttr . '/>';
        }

        if (is_int($value) || (is_string($value) && preg_match('/^-?\d+$/', $value) === 1)) {
            return '<c r="' . $ref . '"' . $styleAttr . '><v>' . (int) $value . '</v></c>';
        }

        if (is_float($value) || (is_string($value) && is_numeric($value))) {
            return '<c r="' . $ref . '"' . $styleAttr . '><v>' . (float) $value . '</v></c>';
        }

        $text = htmlspecialchars((string) $value, ENT_XML1 | ENT_QUOTES, 'UTF-8');

        return '<c r="' . $ref . '" t="inlineStr"' . $styleAttr . '><is><t>' . $text . '</t></is></c>';
    }

    private function columnLetter(int $column): string
    {
        $letter = '';
        while ($column > 0) {
            $mod = ($column - 1) % 26;
            $letter = chr(65 + $mod) . $letter;
            $column = intdiv($column - 1, 26);
        }

        return $letter;
    }
}
