import Foundation
import RxSwift

protocol NewsServiceProtocol {
    
    func fetchDataForSearchController(_ searchedQuery: String, _ page: Int) -> Observable<ENews>
    func fetchSources(_ from: SRequest) -> Observable<SourcesModel>
    func fetchNewsWithSources(_ page: Int, _ source: String) -> Observable<ENews>
    func fetchTHNews(_ page: Int, _ category: THCategories) -> Observable<THNews>
    func fetch(_ page: Int) -> Observable<ENews>
}

class NewsService: NewsServiceProtocol {
    
    func fetchSources(_ from: SRequest) -> Observable<SourcesModel> {
        guard let category = from.category, let language = from.language else { fatalError() }
        
        let params: [String:Any] = ["category" : category, "language": language]
        
        return apiRequest(params, endpointType: EndPointType().sourcesResponses)
    }
    
    func fetch(_ page: Int) -> Observable<ENews> {
        
        let fetchRequestData = ERequest(qWord: nil, qInTitle: nil, domains: nil, excludeDomains: nil, fromDate: nil, toDate: nil, language: "en", sortBy: .publishedAt, pageSize: 10, page: page, sources: Constants.sourcesIds)
        
        guard let page = fetchRequestData.page, let pageSize = fetchRequestData.pageSize, let language = fetchRequestData.language, let sources = fetchRequestData.sources, let sortBy = fetchRequestData.sortBy
            else { fatalError() }
        let params: [String:Any] = ["page" : page, "pageSize": pageSize, "language": language, "sources": sources, "sortBy": sortBy]
        
        return apiRequest(params, endpointType: EndPointType().everything)
    }
    
    func fetchTHNews(_ page: Int, _ category: THCategories) -> Observable<THNews> {
        let request = THRequest(country: "us", category: category, qWord: nil, pageSize: 10, page: page)
        
        guard let page = request.page, let country = request.country, let pageSize = request.pageSize, let category = request.category else { fatalError() }
        let params: [String:Any] = ["country" : country, "pageSize": pageSize, "page": page, "category": category]
        
        return apiRequest(params, endpointType: EndPointType().topHeadline)
        
    }
    
    func fetchDataForSearchController(_ searchedQuery: String, _ page: Int) -> Observable<ENews> {
        
        let request =  ERequest(qWord: searchedQuery, qInTitle: nil, domains: nil, excludeDomains: nil, fromDate: nil, toDate: nil, language: "en", sortBy: nil, pageSize: 10, page: page, sources: nil)
        
        guard let page = request.page, let pageSize = request.pageSize, let language = request.language, let qWord = request.qWord else { fatalError("fetchDataforSearchController fatal error") }
        
        let params: [String:Any] = ["page" : page, "pageSize": pageSize, "language": language, "q": qWord]
        
        return apiRequest(params, endpointType: EndPointType().everything)
    }
    
    func fetchNewsWithSources(_ page: Int, _ source: String) -> Observable<ENews> {
        
        let request = ERequest(qWord: nil, qInTitle: nil, domains: nil, excludeDomains: nil, fromDate: nil, toDate: nil, language: "en", sortBy: .publishedAt, pageSize: 10, page: page, sources: source)
        
        
        guard let page = request.page, let pageSize = request.pageSize, let language = request.language, let sources = request.sources else { fatalError() }
        
        let params: [String:Any] = ["sources" : sources, "pageSize": pageSize, "page": page, "language": language]
        
        return apiRequest(params, endpointType: EndPointType().everything)
        
    }
    
    func apiRequest<T: Decodable>(_ params: [String: Any], endpointType: String) -> Observable<T> {
        return Observable<T>.create { observer in
            
            var endpoint = endpointType + "?apiKey=ff5f1bcd02d643f38454768fbc539040"
            
            params.forEach { (key,value) in
                endpoint.append("&\(key)=\(value)")
            }
            
            guard let url = URL(string: endpoint) else { fatalError("fatalerror") }
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in

                if let error = error {
                    observer.onError(error)
                }
                guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                    print("invalid response")
                    return
                }
                guard let data = data else {
                    print("invalid data")
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let news = try decoder.decode(T.self, from: data)
                    observer.onNext(news)
                    observer.onCompleted()
                } catch {
                    observer.onError(error)
                }
            }
            task.resume()
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
