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
    
    init() {
        Command.main()
    }

    var body: some View {
        VStack {
            Spacer()
            Text("Committente")
            Text(fattura.committente.iva.IdCodice)
            Text(fattura.committente.anagrafica.denominazione)
            Spacer()
            Text("Prestatore")
            Text(fattura.prestatore.anagrafica.denominazione)
            Text(fattura.prestatore.sede.indirizzo)
            Spacer()
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
        
        let c = xml["FatturaElettronica"]["FatturaElettronicaHeader"]["CessionarioCommittente"]["DatiAnagrafici"]
        
        builder.committente(iva: c["IdFiscaleIVA"]["IdCodice"].element?.text ?? "",
                            paese: c["IdFiscaleIVA"]["IdPaese"].element?.text ?? "",
                            nome: c["Anagrafica"]["Denominazione"].element?.text ?? "")
        
        let p = xml["FatturaElettronica"]["FatturaElettronicaHeader"]["CedentePrestatore"]
        
        builder.prestatore(iva: p["DatiAnagrafici"]["IdFiscaleIVA"]["IdCodice"].element?.text ?? "",
                           paese: p["DatiAnagrafici"]["IdFiscaleIVA"]["IdPaese"].element?.text ?? "",
                           sede: Sede(indirizzo: p["Sede"]["Indirizzo"].element?.text ?? "",
                                      cap: p["Sede"]["CAP"].element?.text ?? "",
                                      comune: p["Sede"]["Comune"].element?.text ?? "",
                                      provincia: p["Sede"]["Provincia"].element?.text ?? "",
                                      nazione: p["Sede"]["Nazione"].element?.text ?? ""),
                           cfiscale: p["DatiAnagrafici"]["CodiceFiscale"].element?.text ?? "",
                           nome: p["DatiAnagrafici"]["Anagrafica"]["Denominazione"].element?.text ?? "")
        
        return builder.build()
    }

}
