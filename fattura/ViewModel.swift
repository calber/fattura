//
//  ViewModel.swift
//  fattura
//
//  Created by Alberto Negri on 28/7/20.
//  Copyright © 2020 calber. All rights reserved.
//

import Foundation
import SWXMLHash
import ArgumentParser
import Cocoa


class ViewModel: ObservableObject {
    
    @Published private(set) var fattura: Fattura?

    init() {
        CommandVm.main()
        read()
    }
    
    func load(file: String) {
        inputXmlString = file
        read()
    }
    
    private func read() {

        let xmlconfig = SWXMLHash.config {
            config in
            config.shouldProcessNamespaces = true
        }

        let xml = xmlconfig.parse(inputXmlString)
        let builder = FatturaBuilder()
        
        guard xml["FatturaElettronica"].element?.attribute(by: "versione")?.text != nil else {
            showAlert(title: "Error", body: "XML is not a FatturaElettronica")
            fattura = builder.build()
            return
        }
        
        let cessionario = xml["FatturaElettronica"]["FatturaElettronicaHeader"]["CessionarioCommittente"]["DatiAnagrafici"]
        
        builder.committente(iva: cessionario["IdFiscaleIVA"]["IdCodice"].formatElement(),
                            paese: cessionario["IdFiscaleIVA"]["IdPaese"].formatElement(),
                            nome: cessionario["Anagrafica"]["Denominazione"].formatElement())
        
        let prestatore = xml["FatturaElettronica"]["FatturaElettronicaHeader"]["CedentePrestatore"]
        
        builder.prestatore(iva: prestatore["DatiAnagrafici"]["IdFiscaleIVA"]["IdCodice"].formatElement(),
                           paese: prestatore["DatiAnagrafici"]["IdFiscaleIVA"]["IdPaese"].formatElement(),
                           sede: Sede(indirizzo: prestatore["Sede"]["Indirizzo"].formatElement(),
                                      cap: prestatore["Sede"]["CAP"].formatElement(),
                                      comune: prestatore["Sede"]["Comune"].formatElement(),
                                      provincia: prestatore["Sede"]["Provincia"].formatElement(),
                                      nazione: prestatore["Sede"]["Nazione"].formatElement()),
                           cfiscale: prestatore["DatiAnagrafici"]["CodiceFiscale"].formatElement(),
                           nome: prestatore["DatiAnagrafici"]["Anagrafica"]["Denominazione"].formatElement())
        
        let generali = xml["FatturaElettronica"]["FatturaElettronicaBody"]["DatiGenerali"]["DatiGeneraliDocumento"]
        
        builder.datiGenerali(tipo: generali["TipoDocumento"].formatElement(),
                             divisa: generali["Divisa"].formatElement(),
                             data: generali["Data"].formatAsDate(),
                             numero: generali["Numero"].formatElement(),
                             totale: generali["ImportoTotaleDocumento"].formatElement(),
                             arrotondamento: generali["Arrotondamento"].formatElement(),
                             causale: "")
        
        let dettagli = xml["FatturaElettronica"]["FatturaElettronicaBody"]["DatiBeniServizi"]["DettaglioLinee"]
        for item in dettagli.all {
            builder.datiLinea(
                dettaglio: DettaglioLinee(
                    id: item["NumeroLinea"].formatElement(),
                    descrizione: item["Descrizione"].formatElement(),
                    quantita: item["Quantita"].formatElement(),
                    prezzounitario: item["PrezzoUnitario"].formatElement(),
                    prezzototale: item["PrezzoTotale"].formatElement(),
                    aliquotaiva: item["AliquotaIVA"].formatElement())
            )
        }
        let allegati = xml["FatturaElettronica"]["FatturaElettronicaBody"]["Allegati"]
        for (index, item) in allegati.all.enumerated() {
            builder.allegati(allegato: Allegato(id: index,
                                                nome: item["NomeAttachment"].formatElement(),
                                                format: item["FormatoAttachment"].formatElement(),
                                                descrizione: item["DescrizioneAttachment"].formatElement(),
                                                attachment: item["Attachment"].formatElement()))
        }
        
        fattura = builder.build()
    }
    
    func saveBase64StringToPDF(name: String, base64String: String) {
        guard
            var documentsURL = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)).last,
            let convertedData = Data(base64Encoded: base64String)
            else {
            //handle error when getting documents URL
            return
        }
        documentsURL.appendPathComponent(name)
        do {
            try convertedData.write(to: documentsURL)
        } catch {
            showAlert(title: "Error", body: "Cannot save pdf")
        }

        print(documentsURL)
    }

}

private var inputXmlString: String = ""

struct CommandVm: ParsableCommand {
    
    @Option(name: .customLong("NSDocumentRevisionsDebugMode",withSingleDash: true))
    var nsdocumentrevisionsdebugmode = "YES"

    @Argument(help: "Fattura Xml")
    var file: String = ""
    
    mutating func run() {
        
        if(file.isEmpty) {
            inputXmlString = showDialog()
            return
        }
        guard let input = try? String(contentsOfFile: file) else {
            inputXmlString = ""
            return
        }
        inputXmlString = input
    }

}

func showDialog() -> String {
    let dialog = NSOpenPanel();

    dialog.title = "Choose an invoice";
    dialog.allowedFileTypes = ["xml"];
    dialog.showsResizeIndicator = true;
    dialog.showsHiddenFiles = false;
    dialog.allowsMultipleSelection = false;
    dialog.canChooseDirectories = false;

    if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
        if let result = dialog.url {
            do {
                return try String(contentsOfFile: result.path)
            } catch {
                showAlert(title: "Errore", body: "selected file is not readable")
            }
        }
    }
    return ""
}

func showAlert(title: String, body: String) {
    let alert = NSAlert()
    alert.alertStyle = NSAlert.Style.warning
    alert.messageText = title
    alert.informativeText = body
    alert.runModal()
}

extension XMLIndexer {
    func formatAsDate() -> Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.date(from: self.element?.text ?? "") ?? Date(timeIntervalSince1970: TimeInterval(0))
    }
    
    func formatElement() -> String {
        return self.element?.text ?? ""
    }
    
    func formatElement() -> Int {
        return Int(self.element?.text ?? "") ?? 0
    }
    
    func formatElement() -> NSNumber {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.maximumFractionDigits = 2
        nf.roundingMode = .floor
        nf.locale = Locale(identifier: "en")
        return nf.number(from: self.element?.text ?? "0.0") ?? 0
    }
}


