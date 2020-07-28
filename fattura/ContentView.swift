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
        //Command.main()
        nf.numberStyle = .currency
        viewModel = ViewModel()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack {
                Text("Committente").bold()
                Text(viewModel.fattura!.committente.iva.IdCodice)
                Text(viewModel.fattura!.committente.anagrafica.denominazione)
                Divider()
                Text("Prestatore").bold()
                Text(viewModel.fattura!.prestatore.anagrafica.denominazione)
                Text(viewModel.fattura!.prestatore.sede.indirizzo)
                Divider()
                Text(viewModel.fattura!.dati.numero)
                Text(nf.string(from: viewModel.fattura!.dati.totale) ?? "")
            }
            Button(action: {
                try! self.viewModel.load(file: "test2.xml")
            }) {
                Text("load")
            }.padding(.all, 10)
            
            List(viewModel.fattura!.linee, id: \.id) { l in
                Text("\(l.descrizione) \(self.nf.string(from: l.prezzototale) ?? "")")
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
