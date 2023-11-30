//
// Copyright (c) Vatsal Manot
//

import SwiftUIX
import SwiftUIZ

public struct _ChatMessageListNew<Data: RandomAccessCollection, Content: View>: View where Data.Element: Equatable & Identifiable {
    public typealias Item = Data.Element
    
    @Environment(\._chatViewPreferences) private var _chatViewPreferences
    
    private let data: Data
    private let content: (Item) -> Content
    
    private var _chatViewActions = _ChatViewActions()
    
    public init(
        _ data: Data,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.data = data
        self.content = content
    }
    
    public init(
        _ data: Data
    ) where Data.Element: ChatMessageConvertible, Content == AnyView {
        self.init(
            data,
            content: { item in
                let item = item.__conversion()
                
                withEnvironmentValue(\._chatViewActions) { actions in
                    ChatItemView(item: item)
                        .chatMessage(id: item.id, role: try! item.isSender ? .sender : .recipient)
                        .environment(\._chatItemViewActions, .init(from: actions, id: item.id))
                }
                .eraseToAnyView()
            }
        )
    }
    
    public var body: some View {
        _RawChatItemList {
            ForEach(data) { item in
                content(item)
                    .padding(.small)
            }
            
            if _chatViewPreferences?.messageDeliveryState == .sending {
                sendTaskDisclosure
            }
        }
        ._SwiftUIX_defaultScrollAnchor(.bottom)
    }
        
    private var sendTaskDisclosure: some View {
        ProgressView()
            .controlSize(.small)
            .padding(.leading, .extraSmall)
            .modifier(_iMessageBubbleStyle(isSender: false, isBorderless: false))
            .frame(width: .greedy, alignment: .leading)
            .padding(.horizontal)
    }
}

extension _ChatMessageListNew {
    public func onDelete(
        perform fn: @escaping (Item.ID) -> Void
    ) -> Self {
        then {
            $0._chatViewActions.onDelete = { fn($0.as(Item.ID.self)) }
        }
    }
    
    public func onResend(
        perform fn: @escaping (Item.ID) -> Void
    ) -> Self {
        then {
            $0._chatViewActions.onResend = { fn($0.as(Item.ID.self)) }
        }
    }
}
