//
//  ContentView.swift
//  SlotMachine
//
//  Created by Дмитрий Дуденин on 06.04.2022.
//

import SwiftUI
import Combine

struct ContentView: View {
    
    @ObservedObject private var slotViewModel = SlotViewModel()
    
    var body: some View {
        
        VStack {
            Spacer()
            Text(self.slotViewModel.titleText)
            Spacer()
            
            HStack {
                SlotView { Text(self.slotViewModel.slot1Emoji) }
                SlotView { Text(self.slotViewModel.slot2Emoji) }
                SlotView { Text(self.slotViewModel.slot3Emoji) }
            }
            .drawingGroup()
            
            Spacer()
            Button(action: { self.slotViewModel.running.toggle(); self.slotViewModel.gameStarted = true }, label: { Text(self.slotViewModel.buttonText) })
            Spacer()
        }
    }
}

class SlotViewModel: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    private enum EmojiKind: String, CaseIterable {
        case first = "🇷🇺"
        case second = "🇰🇿"
        case third = "🇧🇾"
    }
    
    private let timer = Timer
        .publish(every: 0.1, on: .main, in: .common)
        .autoconnect()
    
    init() {
        self.timer
            .receive(on: RunLoop.main)
            .sink { _ in self.randomize() }
            .store(in: &self.cancellables)
        
        self.$running
            .receive(on: RunLoop.main)
            .combineLatest($gameStarted)
            .map {
                guard !$0 && $1 else { return "— Флэш-рояль, неудачники!\n— Мы в слоты играем" }
                return self.isWinCondition() ? "Изи катка" : "Ты не проигравший до тех пор, пока ты не сдался"
            }
            .assign(to: \.titleText, on: self)
            .store(in: &self.cancellables)
        
        self.$running
            .receive(on: RunLoop.main)
            .map { $0 == true ? "Стоп" : "Испытать удачу" }
            .assign(to: \.self.buttonText, on: self)
            .store(in: &self.cancellables)
    }
    
    private func randomize() {
        guard self.running else { return }
        self.slot1Emoji =
        EmojiKind.allCases[Int.random(in: 0...EmojiKind.allCases.count - 1)].rawValue
        self.slot2Emoji =         EmojiKind.allCases[Int.random(in: 0...EmojiKind.allCases.count - 1)].rawValue
        self.slot3Emoji =         EmojiKind.allCases[Int.random(in: 0...EmojiKind.allCases.count - 1)].rawValue
    }
    
    private func isWinCondition() -> Bool {
        return self.slot1Emoji == self.slot2Emoji &&
        self.slot2Emoji == self.slot3Emoji
    }
    
    @Published var running = false
    @Published var gameStarted = false
    
    @Published var slot1Emoji = EmojiKind.first.rawValue
    @Published var slot2Emoji = EmojiKind.second.rawValue
    @Published var slot3Emoji = EmojiKind.third.rawValue
    
    @Published var titleText = ""
    @Published var buttonText = ""
}

struct SlotView <Content: View>: View {
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    
    var body: some View {
        self.content()
            .font(.system(size: 64.0))
            .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            .animation(.easeInOut)
            .id(UUID())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
