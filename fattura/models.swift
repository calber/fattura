//
//  models.swift
//  fattura
//
//  Created by Alberto Negri on 27/7/20.
//  Copyright © 2020 calber. All rights reserved.
//

import Foundation

struct Fattura {
    var committente = DatiAnagrafici(iva: IdFiscaleIVA()) //CessionarioCommittente(anagrafica: DatiAnagrafici(iva: IdFiscaleIVA()))
    var prestatore = DatiAnagrafici(iva: IdFiscaleIVA(), sede: Sede())
    var dati = DatiGeneraliDocumento()
    var linee = [DettaglioLinee]()
    var allegati = [Allegato]()
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

struct DatiGeneraliDocumento {
    var tipo: String = ""
    var divisa: String = ""
    var data: Date = Date()
    var numero: String = ""
    var totale: NSNumber = 0.0
    var arrotondamento: NSNumber = 0.0
    var causale: String = ""
}

struct CodiceArticolo {
    var tipo: String = ""
    var valore: String = ""
}
struct AltriDatiGestionali {
    var tipo: String = ""
    var testo: String = ""
}

struct DettaglioLinee: Identifiable {
    var id: Int
    var descrizione = ""
    var quantita: NSNumber = 0
    var prezzounitario: NSNumber = 0.0
    var prezzototale: NSNumber = 0.0
    var aliquotaiva: NSNumber = 0.0
}

struct DatiRiepilogo {
    var aliquotaiva: NSNumber = 0.0
    var imponibileimporto: NSNumber = 0.0
}

struct Allegato: Identifiable {
    var id: Int
    var nome = ""
    var format = ""
    var descrizione = ""
    var attachment = ""
}

class FatturaBuilder {
    private var fattura: Fattura
    
    init() {
        fattura = Fattura()
    }
    
    @discardableResult func committente(iva: String, paese: String, nome: String) -> FatturaBuilder {
        fattura.committente.iva.IdCodice = iva
        fattura.committente.iva.IdPaese = paese
        fattura.committente.anagrafica.denominazione = nome
        return self
    }
    
    @discardableResult func prestatore(iva: String, paese: String, sede: Sede, cfiscale: String, nome: String) -> FatturaBuilder {
        fattura.prestatore.iva.IdCodice = iva
        fattura.prestatore.iva.IdPaese = paese
        fattura.prestatore.codiceFiscale = cfiscale
        fattura.prestatore.anagrafica.denominazione = nome
        fattura.prestatore.sede = sede
        return self
    }
    
    @discardableResult func datiGenerali(tipo: String, divisa: String, data: Date, numero: String, totale: NSNumber, arrotondamento: NSNumber, causale: String) -> FatturaBuilder {
        fattura.dati.tipo = tipo
        fattura.dati.divisa = divisa
        fattura.dati.data = data
        fattura.dati.numero = numero
        fattura.dati.totale = totale
        fattura.dati.arrotondamento = arrotondamento
        fattura.dati.causale = causale
        return self
    }
    
    @discardableResult func allegati(allegato: Allegato) -> FatturaBuilder {
        fattura.allegati.append(allegato)
        return self
    }

    @discardableResult func datiLinea(dettaglio: DettaglioLinee) -> FatturaBuilder {
        fattura.linee.append(dettaglio)
        return self
    }

    func build() -> Fattura {
        return self.fattura
    }
}
