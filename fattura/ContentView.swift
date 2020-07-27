//
//  ContentView.swift
//  fattura
//
//  Created by Alberto Negri on 27/7/20.
//  Copyright © 2020 calber. All rights reserved.
//

import SwiftUI
import XMLTools
import UIKit

struct ContentView: View {
    let fattura = Reader(file: "IT07007590966_SGTK7.xml").read()

    var body: some View {
        VStack {
            Text(fattura.committente.iva.IdCodice)
            Text(fattura.committente.anagrafica.denominazione)
            Text(fattura.prestatore.sede.indirizzo)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

class DocumentPickerViewController: UIDocumentPickerViewController {
    private let onDismiss: () -> Void
    private let onPick: (URL) -> ()

    init(supportedTypes: [String], onPick: @escaping (URL) -> Void, onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        self.onPick = onPick

        super.init(documentTypes: supportedTypes, in: .open)

        allowsMultipleSelection = false
        delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentPickerViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        onPick(urls.first!)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onDismiss()
    }
}

class Reader {

    var xml: XMLTools.Infoset?
    
    init(file: String)  {
        let parser = XMLTools.Parser()

        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            do {
                let text2 = try String(contentsOf: fileURL, encoding: .utf8)
                parser.options.trimWhitespaces = true
                
                xml = try parser.parse(string: text2)
                xml?.namespaceContext.declare("ns0", uri: "http://ivaservizi.agenziaentrate.gov.it/docs/xsd/fatture/v1.2")
                
            }
            catch {
                debugPrint("\(error)")
            }
        }
        
    }
    
    func read() -> Fattura {
        let builder = FatturaBuilder()
        
        if let c = xml?["FatturaElettronica","FatturaElettronicaHeader","CessionarioCommittente","DatiAnagrafici"] {
            builder.committente(iva: c["IdFiscaleIVA","IdCodice"].text,
                                paese: c["IdFiscaleIVA","IdPaese"].text,
                                nome: c["Anagrafica","Denominazione"].text)
        }
        if let p = xml?["FatturaElettronica","FatturaElettronicaHeader","CedentePrestatore"] {
            builder.prestatore(iva: p["DatiAnagrafici","IdFiscaleIVA","IdCodice"].text,
                               paese: p["DatiAnagrafici","IdFiscaleIVA","IdPaese"].text,
                               sede: Sede(indirizzo: p["Sede","Indirizzo"].text,
                                          cap: p["Sede","CAP"].text,
                                          comune: p["Sede","Comune"].text,
                                          provincia: p["Sede","Provincia"].text,
                                          nazione: p["Sede","Nazione"].text),
                               cfiscale: p["DatiAnagrafici","CodiceFiscale"].text,
                               nome: p["DatiAnagrafici","IdFiscaleIVA","IdPaese"].text)
        }
        return builder.build()
    }

}
