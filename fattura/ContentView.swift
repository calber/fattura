//
//  ContentView.swift
//  fattura
//
//  Created by Alberto Negri on 27/7/20.
//  Copyright © 2020 calber. All rights reserved.
//

import SwiftUI
import SWXMLHash
import ArgumentParser

var fattura = Fattura()

struct ContentView: View {
    let nf = NumberFormatter()

    init() {
        Command.main()
        nf.numberStyle = .currency
    }

    var body: some View {
        VStack {
            VStack {
                Text("Committente")
                Text(fattura.committente.iva.IdCodice)
                Text(fattura.committente.anagrafica.denominazione)
                Divider()
                Text("Prestatore")
                Text(fattura.prestatore.anagrafica.denominazione)
                Text(fattura.prestatore.sede.indirizzo)
                Divider()
                Text(fattura.dati.tipo)
                Text(nf.string(from: fattura.dati.totale) ?? "")
            }
            List(fattura.linee, id: \.id) { l in
                Text("\(l.descrizione) \(l.prezzototale)")
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}


struct Command: ParsableCommand {
    
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
        fattura = Reader(data: input).read()
    }
}

class Reader {
    var xml: XMLIndexer
    
    init(data: String)  {
        xml = SWXMLHash.config {
            config in
            config.shouldProcessNamespaces = true
        }.parse(data)
    }
    
    func read() -> Fattura {
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
                             divisa: "",
                             data: Date(),
                             numero: "",
                             totale: generali["ImportoTotaleDocumento"].formatElement(),
                             arrotondamento: 0.0,
                             causale: "")
        
        let dettagli = xml["FatturaElettronica"]["FatturaElettronicaBody"]["DatiBeniServizi"]["DettaglioLinee"]
        for item in dettagli.all {
            builder.datiLinea(id: item["NumeroLinea"].formatElement(), descrizione: item["Descrizione"].formatElement(), prezzounitario: 0, prezzototale: item["PrezzoTotale"].formatElement(), aliquotaiva: 0)
        }
        

        return builder.build()
    }

}

extension XMLIndexer {
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
