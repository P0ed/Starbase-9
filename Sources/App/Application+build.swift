import Hummingbird
import Logging

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "Starbase_9")
        logger.logLevel = arguments.logLevel ?? .info
        return logger
    }()
    let router = buildRouter()
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "Starbase_9"
        ),
        logger: logger
    )
    return app
}

/// Build router
func buildRouter() -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    router.addMiddleware {
        LogRequestsMiddleware(.info)
    }
    router.get("/") { _, _ in
		let buffer = ByteBuffer(string: html(links: [
			link(text: "Products", path: "products"),
			link(text: "Cart", path: "cart")
		]))
		return Response(
			status: .ok,
			headers: .make(
				contentType: "text/html; charset=utf-8",
				contentLength: buffer.readableBytes
			),
			body: ResponseBody(byteBuffer: buffer)
		)
    }
    return router
}

func link(text: String, path: String) -> String {
	"<a href=\"\(path)\">\(text)</a>"
}

func html(head: String = "", body: String = "") -> String {
	"<html><head>\(head)</head><body>\(body)</body></html>"
}

func html(links: [String]) -> String {
	html(body: links.joined(separator: "<br>"))
}

extension HTTPFields {
	@inlinable
	static func make(
		contentType: String,
		contentLength: Int
	) -> Self {
		var headers = HTTPFields()
		headers.append(.init(name: .contentType, value: contentType))
		headers.append(.init(name: .contentLength, value: contentLength.description))
		return headers
	}
}

struct Product: Codable, Hashable {
	var name: String
	var description: String
	var cost: Int
}

struct Buyer: Codable {
	var name: String
	var address: String
}

struct Order: Codable {
	var buyer: Buyer
	var product: Product
}

actor Ferengi {
	var products: [Product] = []
	var stock: [Product: Int] = [:]
	var orders: [Order] = []

	func buy(product: Product, buyer: Buyer) throws {
		guard let cnt = stock[product], cnt > 0 else { throw BuyError.notInStock }

		orders.append(Order(buyer: buyer, product: product))
		stock[product] = cnt - 1
	}
}

enum BuyError: Error {
	case notInStock
}
