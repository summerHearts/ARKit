//
//  ViewController.swift
//  ARKit_CarContaintor
//
//  Created by mars.yao on 2023/12/12.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var sceneView: ARSCNView!
    
    var pickerView: UIPickerView!
    
    let dimensions = Array(stride(from: 0.1, through: 3.0, by: 0.1))
    var selectedLength: CGFloat = 0.1
    var selectedWidth: CGFloat = 0.1
    var selectedHeight: CGFloat = 0.1
    
    // 当前被操作的节点
    var currentNode: SCNNode?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // 检查是否已经开启AR会话，如果没有，则重新开启
        if sceneView.session.configuration == nil {
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal, .vertical]  // 开启水平面检测
            sceneView.session.run(configuration)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 暂停视图的会话
        sceneView.session.pause()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初始化AR渲染引擎
        initScreenView()
        
        worldTrack()
        
        // 添加矩形盒子
        addBox(width: 0.1, height: 0.1, length: 0.1)
        
        // pickerView
        initPickerView()
        
        // 添加手势
        addGesture()
    }
    
    
    func initScreenView() {
        // 创建AR视图
        sceneView = ARSCNView(frame: view.frame)
        view.addSubview(sceneView)
        
        
        // 创建一个新的场景
        sceneView.scene = SCNScene()
        sceneView.debugOptions = [.showBoundingBoxes, .showWorldOrigin]
        
        // 设置代理
        sceneView.delegate = self
        
        // 显示统计信息（例如fps和时间信息）
        sceneView.showsStatistics = true
        
    }
    
    // 开启水平面检测
    func worldTrack() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal] // 开启水平面检测
        sceneView.session.run(configuration)
    }
    
    func addGesture() {
        // 添加平移手势识别器
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        //        // 添加旋转手势识别器
        //        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(didRotate(_:)))
        //        sceneView.addGestureRecognizer(rotationGesture)
    }
    
    
    func createLines(width: CGFloat, height: CGFloat, length: CGFloat) -> [SCNNode] {
        // 创建8个顶点
        let halfWidth = width / 2
        let halfHeight = height / 2
        let halfLength = length / 2
        let vertices: [SCNVector3] = [
            SCNVector3(-halfWidth, halfHeight, halfLength),   // 左上前
            SCNVector3(halfWidth, halfHeight, halfLength),    // 右上前
            SCNVector3(-halfWidth, -halfHeight, halfLength),  // 左下前
            SCNVector3(halfWidth, -halfHeight, halfLength),   // 右下前
            SCNVector3(-halfWidth, halfHeight, -halfLength),  // 左上后
            SCNVector3(halfWidth, halfHeight, -halfLength),   // 右上后
            SCNVector3(-halfWidth, -halfHeight, -halfLength), // 左下后
            SCNVector3(halfWidth, -halfHeight, -halfLength)   // 右下后
        ]
        
        // 定义矩形的12条边
        let indices: [(Int, Int)] = [
            (0, 1), (1, 3), (3, 2), (2, 0), // 前面
            (4, 5), (5, 7), (7, 6), (6, 4), // 后面
            (0, 4), (1, 5), (2, 6), (3, 7)  // 连接前后
        ]
        
        // 创建线段
        var lines: [SCNNode] = []
        for (startIdx, endIdx) in indices {
            let line = lineFrom(vector: vertices[startIdx], toVector: vertices[endIdx])
            lines.append(line)
        }
        
        return lines
    }
    
    @discardableResult
    func addBox(width: CGFloat, height: CGFloat, length: CGFloat) -> SCNNode {
        // 创建线框矩形的每条边
        let lines = createLines(width: width, height: height, length: length)
        
        // 创建一个空节点作为矩形的父节点
        let wireframeNode = SCNNode()
        
        // 将所有边添加到父节点
        for line in lines {
            wireframeNode.addChildNode(line)
        }
        
        // 设置节点的位置（例如场景中心）
        wireframeNode.position = SCNVector3(0, 0, -1) // 5米前的空间
        
        // 给节点一个名字，以便在手势处理中识别
        wireframeNode.name = "movable"
        
        currentNode = wireframeNode
        
        // 添加尺寸标签
        addDimensionText("宽: \(width)m", to: wireframeNode, at: SCNVector3(width / 2, 0, 0), alignedTo: SCNVector3(1, 0, 0))
        addDimensionText("高: \(height)m", to: wireframeNode, at: SCNVector3(0, height / 2, 0), alignedTo: SCNVector3(0, 1, 0))
        addDimensionText("长: \(length)m", to: wireframeNode, at: SCNVector3(0, 0, length / 2), alignedTo: SCNVector3(0, 0, 1))
        // 添加到场景中
        sceneView.scene.rootNode.addChildNode(wireframeNode)
        
        return wireframeNode
    }
    
    func addDimensionText(_ text: String, to node: SCNNode, at position: SCNVector3, alignedTo direction: SCNVector3) {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.yellow
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = position
        textNode.scale = SCNVector3(0.001, 0.001, 0.001) // 缩小文本尺寸
        
        // 调整文本方向
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = .Y
        textNode.constraints = [billboardConstraint]
        
        // 计算旋转角度使文本与边平行
        textNode.eulerAngles = SCNVector3(0, atan2(direction.z, direction.x) - Float.pi / 2, 0)
        
        node.addChildNode(textNode)
    }
    
    func addWireframeBox(width: CGFloat, height: CGFloat, length: CGFloat) {
        
        let posion = currentNode?.position
        // 移除旧的线框盒子（如果存在）
        currentNode?.removeFromParentNode()
        
        // 创建新的线框盒子
        let wireframeBox = addBox(width: width, height: height, length: length)
        wireframeBox.position = posion!
        sceneView.scene.rootNode.addChildNode(wireframeBox)
        
        // 保存对新创建的线框盒子的引用
        currentNode = wireframeBox
    }
    
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNNode {
        let lineNode = createThickLine(from: vector1, to: vector2, thickness: 0.005)
        let yellowMaterial = SCNMaterial()
        yellowMaterial.diffuse.contents = UIColor.yellow  // 将颜色改为黄色
        lineNode.geometry?.firstMaterial = yellowMaterial
        return lineNode
    }
    
    func createThickLine(from start: SCNVector3, to end: SCNVector3, thickness: CGFloat) -> SCNNode {
        let w = SCNVector3(x: end.x - start.x, y: end.y - start.y, z: end.z - start.z)
        let l = CGFloat(sqrt(w.x * w.x + w.y * w.y + w.z * w.z))
        
        let cylinder = SCNCylinder(radius: thickness, height: l)
        cylinder.radialSegmentCount = 6 // 调整以获得更平滑的外观
        let node = SCNNode(geometry: cylinder)
        
        // 将圆柱体放置在两点之间
        node.position = SCNVector3((start.x + end.x) / 2, (start.y + end.y) / 2, (start.z + end.z) / 2)
        node.eulerAngles = SCNVector3(Float.pi / 2, acos((end.z - start.z) / Float(l)), atan2((end.y - start.y), (end.x - start.x)))
        
        return node
    }
    
    
    func updateBoxSize(length: CGFloat, width: CGFloat, height: CGFloat) {
        let box = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
        // 保留原来的材质或应用新的材质
        box.materials = currentNode?.geometry?.materials ?? [SCNMaterial()]
        
        // 更新节点的几何形状
        currentNode?.geometry = box
    }
    
    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        
        switch gesture.state {
        case .began:
            // 检测平移手势开始时触摸的是哪个节点
            let hitTestResult = sceneView.hitTest(location, options: nil)
            if let hitNode = hitTestResult.first?.node, hitNode.name == "movable" {
                currentNode = hitNode
            }
        case .changed:
            // 在平移手势进行中更新节点的位置
            guard let currentNode = currentNode else { return }
            // 使用raycastQuery替代弃用的hitTest方法
            if let query = sceneView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any),
               let hitTestResult = sceneView.session.raycast(query).first {
                let transform = hitTestResult.worldTransform
                let newPosition = SCNVector3(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
                currentNode.position = newPosition
            }
        default:
            // 清除当前节点的引用
            //            currentNode = nil
            print("\(String(describing: currentNode))")
            
        }
    }
    
    @objc func didRotate(_ gesture: UIRotationGestureRecognizer) {
        let location = gesture.location(in: sceneView)
        print("Rotation: \(gesture.rotation), Current Angle: \(String(describing: currentNode?.eulerAngles.y))")
        
        switch gesture.state {
        case .began:
            // 检测旋转手势开始时触摸的是哪个节点
            let hitTestResult = sceneView.hitTest(location)
            if let hitNode = hitTestResult.first?.node, hitNode.name == "movable" {
                currentNode = hitNode
            }
        case .changed:
            // 在旋转手势进行中更新节点的旋转
            guard let currentNode = currentNode else { return }
            let rotation = Float(gesture.rotation)
            currentNode.eulerAngles.z += rotation
            gesture.rotation = 0
        default:
            // 清除当前节点的引用
            //            currentNode = nil
            print("\(String(describing: currentNode))")
        }
    }
    
    func initPickerView() {
        // 创建PickerView
        pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        self.view.addSubview(pickerView)
        
        // 设置PickerView的位置和大小
        setupPickerViewConstraints()
    }
    
    func setupPickerViewConstraints() {
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        pickerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        pickerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        pickerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3 // 长、宽、高
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return dimensions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        "\(dimensions[row]) m"
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            selectedLength =  dimensions[row]
        case 1:
            selectedWidth = dimensions[row]
        case 2:
            selectedHeight = dimensions[row]
        default:
            break
        }
        print(" \(selectedLength) -  \(selectedWidth) -  \(selectedHeight)")
        addWireframeBox(width: selectedWidth, height: selectedHeight, length: selectedLength)
    }
    
    func applyShaderToBox(boxNode: SCNNode) {
        guard let material = boxNode.geometry?.firstMaterial else { return }
        
        let shaderProgram = """
        #include <metal_stdlib>
        using namespace metal;
        
        struct VertexIn {
            float4 position [[attribute(SCNVertexSemanticPosition)]];
        };
        
        vertex float4 vertex_main(const VertexIn vertex_in [[stage_in]]) {
            return vertex_in.position;
        }
        
        fragment float4 fragment_main() {
            return float4(1, 0, 0, 1); // 红色
        }
        """
        
        material.shaderModifiers = [.surface: shaderProgram]
    }
    
}

extension SCNGeometry {
    static func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

// 为方便起见，扩展 SCNVector3 以支持基本向量运算
extension SCNVector3 {
    static func -(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
    }
    
    static func +(left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
    }
    
    static func /(left: SCNVector3, right: Float) -> SCNVector3 {
        return SCNVector3Make(left.x / right, left.y / right, left.z / right)
    }
    
    func length() -> Float {
        return sqrtf(x*x + y*y + z*z)
    }
}
