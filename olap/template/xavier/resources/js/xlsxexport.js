/*

Copyright 2014 - 2017 Roland Bouman (roland.bouman@gmail.com)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/
var XlsxExporter;

(function(){
/*
* See: https://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet(v=office.14).aspx
*/

(XlsxExporter = function(){
}).prototype = {
  mimetype: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  extension: "xlsx",
  getAppXml: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
      "<Properties xmlns=\"http://schemas.openxmlformats.org/officeDocument/2006/extended-properties\" xmlns:vt=\"http://schemas.openxmlformats.org/officeDocument/2006/docPropsVTypes\"><TotalTime>0</TotalTime><Application>LibreOffice/4.1.3.2$Linux_X86_64 LibreOffice_project/410m0$Build-2</Application></Properties>"
    ].join("\n");
  },
  getCoreXml: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
      "<cp:coreProperties xmlns:cp=\"http://schemas.openxmlformats.org/package/2006/metadata/core-properties\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcmitype=\"http://purl.org/dc/dcmitype/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"><dcterms:created xsi:type=\"dcterms:W3CDTF\">2015-03-14T02:06:42Z</dcterms:created><dc:creator>Roland Bouman</dc:creator><cp:revision>0</cp:revision></cp:coreProperties>"
    ].join("\n");
  },
  packDocProps: function(){
    var docProps = this.jsZip.folder("docProps");
    docProps.file("app.xml", this.getAppXml());
    docProps.file("core.xml", this.getCoreXml());
  },
  getDotRels: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
      "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"xl/workbook.xml\"/>",
      "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties\" Target=\"docProps/core.xml\"/>",
      "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties\" Target=\"docProps/app.xml\"/>",
      "</Relationships>"
    ].join("\n");
  },
  pack_Rels: function(){
    var _rels = this.jsZip.folder("_rels");
    _rels.file(".rels", this.getDotRels());
  },
  getWorkbookXmlRels: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">",
      "<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles\" Target=\"styles.xml\"/>",
      "<Relationship Id=\"rId2\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet\" Target=\"worksheets/sheet1.xml\"/>",
      "<Relationship Id=\"rId3\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings\" Target=\"sharedStrings.xml\" />",
      "</Relationships>"
    ].join("\n");
  },
  getTheme1Xml: function(){
  },
  getSheet1Xml: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
      "<worksheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\">",
        "<sheetPr filterMode=\"false\">",
            "<pageSetUpPr fitToPage=\"false\"/>",
        "</sheetPr>",
        "<sheetViews>",
            "<sheetView colorId=\"64\" defaultGridColor=\"true\" rightToLeft=\"false\" showFormulas=\"false\" showGridLines=\"true\" showOutlineSymbols=\"true\" showRowColHeaders=\"true\" showZeros=\"true\" tabSelected=\"true\" topLeftCell=\"A1\" view=\"normal\" windowProtection=\"false\" workbookViewId=\"0\" zoomScale=\"100\" zoomScaleNormal=\"100\" zoomScalePageLayoutView=\"100\">",
                "<selection activeCell=\"A1\" activeCellId=\"0\" pane=\"topLeft\" sqref=\"A1\"/>",
            "</sheetView>",
        "</sheetViews>",
        "<sheetFormatPr defaultRowHeight=\"12.8\"/>",
        this.getSheetContentsXml(),
        "<printOptions headings=\"false\" gridLines=\"false\" gridLinesSet=\"true\" horizontalCentered=\"false\" verticalCentered=\"false\"/>",
        "<pageMargins left=\"0.7\" right=\"0.7\" top=\"0.7\" bottom=\"0.7\" header=\"0.3\" footer=\"0.3\"/>",
        "<pageSetup blackAndWhite=\"false\" cellComments=\"none\" copies=\"1\" draft=\"false\" firstPageNumber=\"1\" fitToHeight=\"1\" fitToWidth=\"1\" horizontalDpi=\"300\" orientation=\"portrait\" pageOrder=\"downThenOver\" paperSize=\"1\" scale=\"100\" useFirstPageNumber=\"true\" usePrinterDefaults=\"false\" verticalDpi=\"300\"/>",
        "<headerFooter differentFirst=\"false\" differentOddEven=\"false\">",
            "<oddHeader>&amp;C&amp;\"Times New Roman,Regular\"&amp;12&amp;A</oddHeader>",
            "<oddFooter>&amp;C&amp;\"Times New Roman,Regular\"&amp;12Page &amp;P</oddFooter>",
        "</headerFooter>",
      "</worksheet>"
    ].join("\n");
  },
  getSharedStringsXml: function(){
    var sharedStrings = this.sharedStrings, xml = "";
    var i, n = sharedStrings.length;
    for (i = 0; i < n; i++) {
      xml += "<si><t>" + escXml(String(sharedStrings[i])) + "</t></si>";
    }
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
      "<sst xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" count=\"" + n + "\" uniqueCount=\"" + n + "\">",
      xml,
      "</sst>"
    ].join("\n");
  },
  getSharedString: function(string){
    var sharedStrings = this.sharedStrings;
    var index = sharedStrings.indexOf(string);
    if (index === -1) {
      index = sharedStrings.length;
      sharedStrings.push(string);
    }
    return "<v>" + index + "</v>";
  },
  getStylesXml: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
      "<styleSheet xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\">",
        "<numFmts count=\"1\">",
          "<numFmt formatCode=\"GENERAL\" numFmtId=\"164\"/>",
        "</numFmts>",
        "<fonts count=\"4\">",
          "<font><sz val=\"10\"/><name val=\"Arial\"/><family val=\"2\"/></font>",
          "<font><sz val=\"10\"/><name val=\"Arial\"/><family val=\"0\"/></font>",
          "<font><sz val=\"10\"/><name val=\"Arial\"/><family val=\"0\"/></font>",
          "<font><sz val=\"10\"/><name val=\"Arial\"/><family val=\"0\"/></font>",
        "</fonts>",
        "<fills count=\"2\">",
          "<fill><patternFill patternType=\"none\"/></fill>",
          "<fill><patternFill patternType=\"gray125\"/></fill>",
        "</fills>",
        "<borders count=\"1\">",
          "<border diagonalDown=\"false\" diagonalUp=\"false\"><left/><right/><top/><bottom/><diagonal/></border>",
        "</borders>",
        "<cellStyleXfs count=\"20\">",
          "<xf applyAlignment=\"true\" applyBorder=\"true\" applyFont=\"true\" applyProtection=\"true\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"164\">",
            "<alignment horizontal=\"general\" indent=\"0\" shrinkToFit=\"false\" textRotation=\"0\" vertical=\"bottom\" wrapText=\"false\"/>",
            "<protection hidden=\"false\" locked=\"true\"/>",
          "</xf>",
          "<xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"2\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"2\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"0\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"43\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"41\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"44\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"42\"></xf><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"true\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"1\" numFmtId=\"9\"></xf></cellStyleXfs><cellXfs count=\"1\"><xf applyAlignment=\"false\" applyBorder=\"false\" applyFont=\"false\" applyProtection=\"false\" borderId=\"0\" fillId=\"0\" fontId=\"0\" numFmtId=\"164\" xfId=\"0\"><alignment horizontal=\"general\" indent=\"0\" shrinkToFit=\"false\" textRotation=\"0\" vertical=\"bottom\" wrapText=\"false\"/><protection hidden=\"false\" locked=\"true\"/></xf>",
        "</cellXfs>",
        "<cellStyles count=\"6\">",
          "<cellStyle builtinId=\"0\" customBuiltin=\"false\" name=\"Normal\" xfId=\"0\"/>",
          "<cellStyle builtinId=\"3\" customBuiltin=\"false\" name=\"Comma\" xfId=\"15\"/>",
          "<cellStyle builtinId=\"6\" customBuiltin=\"false\" name=\"Comma [0]\" xfId=\"16\"/>",
          "<cellStyle builtinId=\"4\" customBuiltin=\"false\" name=\"Currency\" xfId=\"17\"/>",
          "<cellStyle builtinId=\"7\" customBuiltin=\"false\" name=\"Currency [0]\" xfId=\"18\"/>",
          "<cellStyle builtinId=\"5\" customBuiltin=\"false\" name=\"Percent\" xfId=\"19\"/>",
        "</cellStyles>",
      "</styleSheet>"
    ].join("\n");
  },
  getWorkBookXml: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>",
      "<workbook xmlns=\"http://schemas.openxmlformats.org/spreadsheetml/2006/main\" xmlns:r=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships\"><fileVersion appName=\"Calc\"/><workbookPr backupFile=\"false\" showObjects=\"all\" date1904=\"false\"/><workbookProtection/><bookViews><workbookView activeTab=\"0\" firstSheet=\"0\" showHorizontalScroll=\"true\" showSheetTabs=\"true\" showVerticalScroll=\"true\" tabRatio=\"141\" windowHeight=\"8192\" windowWidth=\"16384\" xWindow=\"0\" yWindow=\"0\"/></bookViews><sheets><sheet name=\"Sheet1\" sheetId=\"1\" state=\"visible\" r:id=\"rId2\"/></sheets><calcPr iterateCount=\"100\" refMode=\"A1\" iterate=\"false\" iterateDelta=\"0.001\"/></workbook>"
    ].join("\n");
  },
  packXl: function(){
    var xl = this.jsZip.folder("xl");

    var _rels = xl.folder("_rels");
    _rels.file("workbook.xml.rels", this.getWorkbookXmlRels());

    //var theme = xl.folder("theme");
    //theme.file("theme1.xml", this.getTheme1Xml());

    var worksheets = xl.folder("worksheets");
    worksheets.file("sheet1.xml", this.getSheet1Xml());

    xl.file("sharedStrings.xml", this.getSharedStringsXml());
    xl.file("styles.xml", this.getStylesXml());
    xl.file("workbook.xml", this.getWorkBookXml());
  },
  getSheetContentsXml: function(){
    var xml;
    xml = "<sheetData>" + this.rowsXml + "</sheetData>";
    var mergedCells = this.mergedCells;
    if (mergedCells.length) {
      xml += "<mergeCells count=\"" + mergedCells.length + "\">" + mergedCells.join("") + "</mergeCells>";
    }
    return xml;
  },
  getColumnAddress: function(i){
    var address = "", a, d;
    d = 26*26;
    a = i / d;
    if (a > 1) {
      a = parseInt(a, 10);
      i -= a*d;
      address += String.fromCharCode(64+a);
    }
    d = 26;
    a = i / d;
    if (a > 1) {
      a = parseInt(a, 10);
      i -= a*d;
      address += String.fromCharCode(64+a);
    }
    if (i >= 1) {
      address += String.fromCharCode(64+i);
    }
    return address;
  },
  exportPivotTable: function(pivotTable){
    var rowsXml = this.rowsXml;
    var line = "", l;
    rowsXml.push("<row></row>");
    var mergedCells = this.mergedCells = [];
    var dataset = pivotTable.getDataset();
    if (dataset) {
      var columnsOffset = 1, rowOffset = 1;
      var rowAxis, columnAxis;
      if (dataset.hasRowAxis()) {
        rowAxis = dataset.getRowAxis();
        columnsOffset += rowAxis.hierarchyCount();
        rowsTable = pivotTable.getRowsTableDom();
      }
      var member, caption, ref, type = "s", style = "0";

      //render the column axis
      if (dataset.hasColumnAxis()) {
        columnAxis = dataset.getColumnAxis();
        rowOffset += columnAxis.hierarchyCount();
        l = rowsXml.length + 1;
        columnAxis.eachHierarchy(function(hierarchy){
          line = "";
          columnAxis.eachTuple(function(tuple){
            member = tuple.members[hierarchy.index];
            caption = member[Xmla.Dataset.Axis.MEMBER_CAPTION];
            ref = this.getColumnAddress(columnsOffset + tuple.index) + String(hierarchy.index + l);
            line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
            line += this.getSharedString(caption);
            line += "</c>";
          }, this);
          rowsXml.push("<row>" + line + "</row>");
        }, this);
      }

      //render the cell set
      var cellSet = dataset.getCellset();
      cellSet.reset();

      if (dataset.hasRowAxis()) {
        var hasMoreCells = true,
            ordinal = cellSet.cellOrdinal(),
            minOrdinal, maxOrdinal,
            n = columnAxis.tupleCount()
        ;
        //multiple rows of cells.
        l = rowsXml.length + 1;
        rowAxis.eachTuple(function(tuple){
          line = "";
          type = "s";
          minOrdinal = tuple.index * n;
          maxOrdinal = minOrdinal + n;
          rowAxis.eachHierarchy(function(hierarchy){
            member = tuple.members[hierarchy.index];
            caption = escXml(member[Xmla.Dataset.Axis.MEMBER_CAPTION]);
            ref = this.getColumnAddress(hierarchy.index + 1) + String(tuple.index + l);
            line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
            line += this.getSharedString(caption);
            line += "</c>";
          }, this);
          if (hasMoreCells && ordinal >= minOrdinal && ordinal < maxOrdinal) {
            do {
              ref = this.getColumnAddress(columnsOffset + (ordinal - minOrdinal));
              ref += String(tuple.index + l);
              type = "n";
              line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
              line += "<v>" + cellSet.cellValue() + "</v>";
              line += "</c>";
              ordinal = cellSet.nextCell();
            } while ((hasMoreCells = (ordinal !== -1)) && ordinal < maxOrdinal);
          }
          rowsXml.push("<row>" + line + "</row>");
        }, this);
      }
      else {
        //either a column axis, or no column axis.
        //in both cases, we have one row of cells
        line = "";
        l = rowsXml.length + 1;
        type = "n";
        cellSet.eachCell(function(cell){
          ref = this.getColumnAddress(columnsOffset + cell.ordinal) + String(l);
          line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
          line += "<v>" + cell.Value + "</v>";
          line += "</c>";
        }, this);
        rowsXml.push("<row> " + line + "</row>");
      }
    }
  },
  exportDataTable: function(dataTable){
    var rowsXml = this.rowsXml;
    var mergedCells = this.mergedCells = [];
    var dataset = dataTable.getDataset();
    var line;
    rowsXml.push("<row></row>");
    if (dataset) {
      var columns = [];
      var dataGrid = dataTable.getDataGrid();
      line = "";
      n = rowsXml.length + 1;
      dataGrid.eachColumn(function(i, column){
        columns.push(column);
        var ref = this.getColumnAddress(i+1) + String(n), type = "s", style = "0";
        line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
        line += this.getSharedString(column.label || column.name);
        line += "</c>";
      }, this);
      rowsXml.push("<row>" + line + "</row>");

      n = rowsXml.length + 1;
      dataGrid.eachRow(function(i, rowValues, cellValues){
        line = "";
        var numRowHeaders = rowValues ? rowValues.length.length : 0;
        for (j = 0; j < numRowHeaders; j++) {
          var ref = this.getColumnAddress(j+1) + String(i+n), type = "s", style = "0";
          line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
          line += this.getSharedString(rowValues[j]);
          line += "</c>";
        }
        var value, column;
        for (j = 0; j < cellValues.length; j++) {
          value = cellValues[j];
          if (iUnd(value)) {
            continue;
          }
          var ref = this.getColumnAddress(numRowHeaders + j + 1) + String(numRowHeaders + n + i),
              type,
              style = "0"
          ;
          column = dataGrid.getColumn(j)
          if (column.isMeasure){
            type = "n";
            line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
            line += "<v>" + value + "</v>";
            line += "</c>";
          }
          else {
            type = "s";
            value = this.getSharedString(value);
            line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
            line += value;
            line += "</c>";
          }
        }
        rowsXml.push("<row>" +line + "</row>");
      }, this)
    }
  },
  getContentXml: function(){
    return [
      "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
      "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">",
      "<Override PartName=\"/_rels/.rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>",
      "<Override PartName=\"/docProps/app.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.extended-properties+xml\"/>",
      "<Override PartName=\"/docProps/core.xml\" ContentType=\"application/vnd.openxmlformats-package.core-properties+xml\"/>",
      "<Override PartName=\"/xl/_rels/workbook.xml.rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>",
      "<Override PartName=\"/xl/sharedStrings.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml\" />",
      "<Override PartName=\"/xl/worksheets/sheet1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml\"/>",
      "<Override PartName=\"/xl/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml\"/>",
      "<Override PartName=\"/xl/workbook.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml\"/>",
      "</Types>"
    ].join("\n");
  },
  pack: function(){
    this.jsZip = new JSZip();
    this.packDocProps();
    this.pack_Rels();
    this.packXl();
    this.jsZip.file("[Content_Types].xml", this.getContentXml());
  },
  getContent: function(){
    var mimetype = this.mimetype;
    return "data:" + mimetype + ";base64," + encodeURIComponent(this.jsZip.generate());
    //window.open(this.getContent());
  },
  createSlicerAxisHeaders: function(queryDesigner) {
    if (!queryDesigner.hasSlicerAxis()) {
      return;
    }
    var slicerAxis = queryDesigner.getSlicerAxis();
    if (slicerAxis.getHierarchyCount() === 0) {
      return;
    }
    var rowsXml = this.rowsXml;
    var line, n, ref, type = "s", style = "0";
    rowsXml.push("<row></row>");
    n = rowsXml.length + 1;
    line = "";

    ref = this.getColumnAddress(1) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(gMsg("Selection") + ":");
    line += "</c>";

    rowsXml.push("<row>" + line + "</row>");

    line = "";
    slicerAxis.eachHierarchy(function(hierarchy, hierarchyIndex){
      n = rowsXml.length + 1;

      ref = this.getColumnAddress(1) + String(n);
      line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
      line += this.getSharedString(hierarchy.HIERARCHY_CAPTION + ":");
      line += "</c>";

      var memberList = "";
      slicerAxis.eachSetDef(function(setDef, setDefIndex){
        if (setDefIndex){
          memberList += ", ";
        }
        memberList += setDef.metadata.MEMBER_CAPTION;
      }, this, hierarchy);

      ref = this.getColumnAddress(2) + String(n);
      line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
      line += this.getSharedString(memberList);
      line += "</c>";

      rowsXml.push("<row>" + line + "</row>");
    }, this);
  },
  createExportHeaders: function(title, catalogName, cubeName, visualizer, queryDesigner) {
    var rowsXml = this.rowsXml, line, n, ref, type = "s", style = 0;
    //title row
    line = "";
    n = rowsXml.length + 1;

    ref = this.getColumnAddress(1) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(gMsg("Title") + ":");
    line += "</c>";

    ref = this.getColumnAddress(2) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(title);
    line += "</c>";

    rowsXml.push("<row>" + line + "</row>");

    //catalog row
    line = "";
    n = rowsXml.length + 1;

    ref = this.getColumnAddress(1) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(gMsg("Catalog") + ":");
    line += "</c>";

    ref = this.getColumnAddress(2) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(catalogName);
    line += "</c>";

    rowsXml.push("<row>" + line + "</row>");

    //cube row
    line = "";
    n = rowsXml.length + 1;

    ref = this.getColumnAddress(1) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(gMsg("Cube") + ":");
    line += "</c>";

    ref = this.getColumnAddress(2) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(cubeName);
    line += "</c>";

    rowsXml.push("<row>" + line + "</row>");

    //export date row
    line = "";
    n = rowsXml.length + 1;

    ref = this.getColumnAddress(1) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(gMsg("Export Date") + ":");
    line += "</c>";

    //TODO: output this as a proper date. Example is here
    //https://msdn.microsoft.com/en-us/library/documentformat.openxml.spreadsheet.cellvalue(v=office.14).aspx
    //for some reason it doesn't work at least not for OO Calc.
    ref = this.getColumnAddress(2) + String(n);
    line += "<c r=\"" + ref + "\" s=\"" + style + "\" t=\"" + type + "\">";
    line += this.getSharedString(gMsg(isoDateTimeString()));
    line += "</c>";

    rowsXml.push("<row>" + line + "</row>");
  },
  doExport: function(name, catalogName, cubeName, visualizer, queryDesigner){
    this.rowsXml = [];
    this.sharedStrings = [];

    this.createExportHeaders(name, catalogName, cubeName, visualizer, queryDesigner);
    this.createSlicerAxisHeaders(queryDesigner);

    if (visualizer instanceof PivotTable) {
      this.exportPivotTable(visualizer, queryDesigner);
    }
    else
    if (visualizer instanceof DataTable) {
      this.exportDataTable(visualizer, queryDesigner);
    }
    else
    if (visualizer instanceof CorrelationMatrix) {
      this.exportDataTable(visualizer, queryDesigner);
    }
    else {
      throw "Don't know how to export this type of object.";
    }
    this.rowsXml = this.rowsXml.join("");
    this.pack();
    var content = this.jsZip.generate({type: "blob"});
    saveAs(content, name + "." + this.extension);
  }
};

})();