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


class ViewModel: ObservableObject {
    
    @Published private(set) var fattura: Fattura?

    init() {
        CommandVm.main()
        read()
    }
    
    func load(file: String) throws {
        guard let input = try? String(contentsOfFile: file) else {
            throw RuntimeError("Couldn't read from '\(file)'!")
        }
        inputXmlString = input
        read()
    }
    
    private func read() {

        let xmlconfig = SWXMLHash.config {
            config in
            config.shouldProcessNamespaces = true
        }

        let xml = xmlconfig.parse(inputXmlString)
        let builder = FatturaBuilder()
        
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
                             arrotondamento: 0.0,
                             causale: "")
        
        let dettagli = xml["FatturaElettronica"]["FatturaElettronicaBody"]["DatiBeniServizi"]["DettaglioLinee"]
        for item in dettagli.all {
            builder.datiLinea(id: item["NumeroLinea"].formatElement(), descrizione: item["Descrizione"].formatElement(), prezzounitario: 0, prezzototale: item["PrezzoTotale"].formatElement(), aliquotaiva: 0)
        }
        
        
        fattura = builder.build()
    }
}

private var inputXmlString: String = ""

struct CommandVm: ParsableCommand {
    
    @Flag(help: "provide a xml")
    var xml = false

    @Option(name: .customLong("NSDocumentRevisionsDebugMode",withSingleDash: true))
    var nsdocumentrevisionsdebugmode = "YES"

    @Argument(help: "Fattura Xml")
    var file: String
    
    mutating func run() throws {
        guard let input = try? String(contentsOfFile: file) else {
            throw RuntimeError("Couldn't read from '\(file)'!")
        }
        inputXmlString = input
    }
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


