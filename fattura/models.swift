//
//  models.swift
//  fattura
//
//  Created by Alberto Negri on 27/7/20.
//  Copyright © 2020 calber. All rights reserved.
//

import Foundation
import XMLTools

struct Fattura {
    var committente = DatiAnagrafici(iva: IdFiscaleIVA()) //CessionarioCommittente(anagrafica: DatiAnagrafici(iva: IdFiscaleIVA()))
    var prestatore = DatiAnagrafici(iva: IdFiscaleIVA(), sede: Sede())
}


struct Sede {
    var indirizzo: String = ""
    var cap: String = ""
    var comune: String = ""
    var provincia: String = ""
    var nazione: String = ""
}

struct Anagrafica {
    var denominazione: String
}

struct DatiGeneraliDocumento {
    
}

struct DatiAnagrafici {
    var iva: IdFiscaleIVA
    var codiceFiscale: String = ""
    var anagrafica: Anagrafica = Anagrafica(denominazione: "")
    var sede: Sede = Sede()
}

struct IdFiscaleIVA {
    var IdPaese: String = ""
    var IdCodice: String = ""
}

class FatturaBuilder {
    private var fattura: Fattura
    
    init() {
        fattura = Fattura()
    }
    
    func committente(iva: String, paese: String, nome: String) -> FatturaBuilder {
        fattura.committente.iva.IdCodice = iva
        fattura.committente.iva.IdPaese = paese
        fattura.committente.anagrafica.denominazione = nome
        return self
    }
    
    func prestatore(iva: String, paese: String, sede: Sede, cfiscale: String, nome: String) -> FatturaBuilder {
        fattura.prestatore.iva.IdCodice = iva
        fattura.prestatore.iva.IdPaese = paese
        fattura.prestatore.codiceFiscale = cfiscale
        fattura.prestatore.anagrafica.denominazione = nome
        fattura.prestatore.sede = sede
        return self
    }

    func build() -> Fattura {
        return self.fattura
    }
}
