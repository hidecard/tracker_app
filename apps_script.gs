// Google Apps Script - Use POST for ALL operations
// Deploy as Web App with: "Execute as: Me" and "Anyone" access

function doGet() {
  const sheet =
    SpreadsheetApp.getActiveSpreadsheet().getSheetByName("transactions");
  const data = sheet.getDataRange().getValues();
  let result = [];

  for (let i = 1; i < data.length; i++) {
    if (data[i][1] == null || data[i][1] == "") continue;
    result.push({
      id: String(data[i][0]),
      date: data[i][1],
      type: data[i][2],
      category: data[i][3],
      amount: data[i][4],
      note: data[i][5] || "",
    });
  }

  return ContentService.createTextOutput(JSON.stringify(result)).setMimeType(
    ContentService.MimeType.JSON,
  );
}

function doPost(e) {
  const sheet =
    SpreadsheetApp.getActiveSpreadsheet().getSheetByName("transactions");
  const data = JSON.parse(e.postData.contents);
  const action = data.action || "add";

  if (action === "add") {
    // Add new transaction
    const lastRow = sheet.getLastRow();
    const newId = lastRow;

    sheet.appendRow([
      newId,
      data.date,
      data.type,
      data.category,
      data.amount,
      data.note || "",
    ]);

    return ContentService.createTextOutput(
      JSON.stringify({ success: true, id: newId, action: "add" }),
    ).setMimeType(ContentService.MimeType.JSON);
  } else if (action === "update") {
    // Update existing transaction
    const idToFind = String(data.id);
    const rows = sheet.getDataRange().getValues();

    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][0]) == idToFind) {
        sheet
          .getRange(i + 1, 2, 1, 5)
          .setValues([
            [data.date, data.type, data.category, data.amount, data.note || ""],
          ]);
        return ContentService.createTextOutput(
          JSON.stringify({ success: true, action: "update" }),
        ).setMimeType(ContentService.MimeType.JSON);
      }
    }
    return ContentService.createTextOutput(
      JSON.stringify({ success: false, error: "ID not found" }),
    ).setMimeType(ContentService.MimeType.JSON);
  } else if (action === "delete") {
    // Delete transaction
    const idToFind = String(data.id);
    const rows = sheet.getDataRange().getValues();

    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][0]) == idToFind) {
        sheet.deleteRow(i + 1);
        return ContentService.createTextOutput(
          JSON.stringify({ success: true, action: "delete" }),
        ).setMimeType(ContentService.MimeType.JSON);
      }
    }
    return ContentService.createTextOutput(
      JSON.stringify({ success: false, error: "ID not found" }),
    ).setMimeType(ContentService.MimeType.JSON);
  }

  return ContentService.createTextOutput(
    JSON.stringify({ success: false, error: "Invalid action" }),
  ).setMimeType(ContentService.MimeType.JSON);
}
