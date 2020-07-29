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

//var fattura = Fattura()

struct ContentView: View {
    let nf = NumberFormatter()
    
    @ObservedObject var viewModel: ViewModel

    init() {
        nf.numberStyle = .currency
        viewModel = ViewModel()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: {
                self.viewModel.load(file: showDialog())
            }) {
                Text("load")
            }.padding(.all, 10)

            VStack(alignment: .leading) {
                Group {
                    Text("Committente").bold()
                    Text(viewModel.fattura!.committente.iva.IdCodice)
                    Text(viewModel.fattura!.committente.anagrafica.denominazione)
                    Divider()
                }
                Group {
                    Text("Prestatore").bold()
                    Text(viewModel.fattura!.prestatore.anagrafica.denominazione)
                    Text(viewModel.fattura!.prestatore.sede.indirizzo)
                    Divider()
                }
                Group {
                    Text("Dati fattura").bold()
                    Text("numero \(viewModel.fattura!.dati.numero)")
                    Text("totale \(nf.string(from: viewModel.fattura!.dati.totale) ?? "")")
                }
            }
            
            List(viewModel.fattura!.linee, id: \.id) { l in
                Dettaglio(dettaglio: l)
            }
            if(!viewModel.fattura!.allegati.isEmpty) {
                List(viewModel.fattura!.allegati, id: \.id) { l in
                    Button(action: {
                        self.viewModel.saveBase64StringToPDF(name: l.nome, base64String: l.attachment)
                    }) {
                        Text("save: \(l.nome)")
                    }.padding(.all, 10)
                }
            }
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Dettaglio: View {
    let currency = NumberFormatter()
    let digit = NumberFormatter()
    let percent = NumberFormatter()
    var d: DettaglioLinee
        
    init(dettaglio: DettaglioLinee) {
        d = dettaglio
        currency.numberStyle = .currency
        percent.numberStyle = .percent
        percent.multiplier = 1.00
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(d.descrizione)
            HStack {
                Text("quantità: \(self.digit.string(from: d.quantita) ?? "")")
                Text(self.currency.string(from: d.prezzototale) ?? "")
                Text(self.percent.string(from: d.aliquotaiva) ?? "")
            }
        }
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
