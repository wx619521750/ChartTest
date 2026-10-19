//
//  ViewController.swift
//  ChartTest
//
//  Created by Carlo on 10/19/26.
//

import UIKit
import SnapKit
class ViewController: UIViewController {
    
    var arr = ["chart","floor"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(tableview)
        tableview.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    

    lazy var tableview: UITableView = {
        let view = UITableView.init(frame: .zero, style: .grouped)
        view.delegate = self
        view.dataSource = self
        view.backgroundColor = .white
        return view
    }()

}

extension ViewController:UITableViewDelegate,UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "aaa")
        cell.textLabel?.text = arr[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            self.navigationController?.pushViewController(ChartViewController(), animated: true)
        }
        if indexPath.row == 1{
            self.navigationController?.pushViewController(RoomPlanViewController(), animated: true)
        }
    }
}
