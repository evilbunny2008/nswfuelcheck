import io.thp.pyotherside 1.5
import QtLocation 5.9
import QtPositioning 5.9
import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.2
import QtQuick.Window 2.2
import Ubuntu.Components 1.3

MainView {
    id: root
    objectName: 'mainView'
    applicationName: 'nswfuelcheck.evilbunny'
    automaticOrientation: true

    width: units.gu(45)
    height: units.gu(75)

    property string fueltype: "U91"
    property int minZoom: 13
    property int defZoom: 15
    property var noos: false
    property var rqsts: false
    property var booted: false
    property var gpsLock: 0

    Plugin {
        id: osmMapPlugin
        name: "osm"
        PluginParameter {
            name: "useragent"
            value: "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/73.0.3683.86 Safari/537.36"
        }
    }

    BusyIndicator {
        id: busyIndicator
        z: map.z + 6
        width: units.gu(20)
        height: units.gu(20)
        anchors.centerIn: parent
        running: true
    }

    Python {
        id: pytest
        Component.onCompleted: {
            addImportPath(Qt.resolvedUrl('.'))
            importModule("main", function() {});
            call("main.get_noos", [], function(results) {
                noos = results[0]
                rqsts = results[1]
                
                if(results[5] != "") {
                    fueltype = results[5]
                    updateFuelType()
                }

                if(results[6] != "") {
                    if(results[6] == 0)
                        gpsLock = 1
                    else
                        gpsLock = 0
                    gpsToggle()
                }
                
                if(results[2] != "") {
                    map.center = QtPositioning.coordinate(results[2], results[3])
                    map.zoomLevel = results[4]
                }

                booted = true
                mapTimer.running = true
            })
        }
        onError: console.log('Python error: ' + traceback)
    }

    Timer {
        id: mapTimer
        running: false
        repeat: false
        interval: 1000

        onTriggered: {
            running = false
            updateMap()
        }
    }
    
    Page {
        id: mapPage
        anchors.fill: parent

        header: PageHeader {
            id: mapHeader
            title: 'NSW Fuel Check'

            trailingActionBar {
                actions: [
                    Action {
                        iconSource: "../assets/list.svg"
                        text: "Show List"

                        onTriggered: switchDisplay()
                    },
                    Action {
                        iconName: "info"
                        text: "About App"

                        onTriggered: aboutPopup1.open()
                    },
                    Action {
                        id: gps1
                        iconSource: "../assets/gps_empty.svg"
                        text: "GPS Lock"

                        onTriggered: gpsToggle()
                    }
                ]
            }
        }

        Popup {
            id: aboutPopup1
            padding: 10
            width: units.gu(37)
            height: about1a.height + about1b.height + about1c.height + about1d.height + about1Button.height + units.gu(1)
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            z: mapPage.z + 6
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

            Text {
                id: about1a
                anchors.top: parent.top
                anchors.left: parent.left
                font.bold: true
                font.pixelSize: units.gu(4.5)
                text: "About this app"
            }

            Text {
                id: about1b
                padding: units.gu(1)
                anchors.top: about1a.bottom
                width: parent.width
                wrapMode: Text.Wrap
                text: "NSW Fuel Check provides real-time information about fuel prices at service stations across NSW and is accessible on any device connected to the internet, including smartphones, tablets, desk top computers and laptops."
            }

            Text {
                id: about1c
                padding: units.gu(1)
                anchors.top: about1b.bottom
                width: parent.width
                wrapMode: Text.Wrap
                font.bold: true
                text: "Warning: Never use your phone while driving, traffic penalties may apply."
            }

            Text {
                id: about1d
                padding: units.gu(1)
                anchors.top: about1c.bottom
                width: parent.width
                wrapMode: Text.Wrap
                font.bold: true
                text: "Note: This is an unofficial app, and is in no way connected with the NSW Government."
            }

            Button {
                id: about1Button
                anchors.top: about1d.bottom
                width: parent.width
                text: "Okay"
                color: "#3eb34f"
                onClicked: {
                    aboutPopup1.close()
                }
            }
        }

        ComboBox {
            id: mapControl
            anchors.top: mapHeader.bottom
            anchors.left: parent.left
            width: parent.width
            height: units.gu(5)
            font.pixelSize: units.gu(3.5)
            model: ["Unleaded 91", "Ethanol 94 (E10)", "Ethanol 105 (E85)", "Premium 95", "Premium 98", "Diesel",
                    "Premium Diesel", "Biodiesel 20", "LPG", "CNG/NGV", "EV charge"]

            delegate: ItemDelegate {
                width: mapControl.width
                contentItem: Text {
                    text: modelData
                    font.pixelSize: units.gu(3.5)
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                highlighted: mapControl.highlightedIndex === index
            }

            onCurrentIndexChanged: {
                if(currentIndex < 0)
                    currentIndex = 0
                else if(currentIndex > 10)
                    currentIndex = 0

                if(booted)
                    pytest.call("main.save_config", [map.center.latitude, map.center.longitude, map.zoomLevel, fueltype, gpsLock], function(results) {})

                listControl.currentIndex = currentIndex
                mapControl.displayText = textAt(currentIndex)
                listControl.displayText = textAt(currentIndex)

                switch(currentIndex) {
                    case 0:
                        fueltype = "U91"
                        break
                    case 1:
                        fueltype = "E10"
                        break
                    case 2:
                        fueltype = "E85"
                        break
                    case 3:
                        fueltype = "P95"
                        break
                    case 4:
                        fueltype = "P98"
                        break
                    case 5:
                        fueltype = "DL"
                        break
                    case 6:
                        fueltype = "PDL"
                        break
                    case 7:
                        fueltype = "B20"
                        break
                    case 8:
                        fueltype = "LPG"
                        break
                    case 9:
                        fueltype = "CNG"
                        break
                    case 10:
                        fueltype = "EV"
                        break
                }

                busyIndicator.running = true
                updateMap()
            }
        }

        Map {
            id: map

            property int lastX: -1
            property int lastY: -1
            property int pressX: -1
            property int pressY: -1
            property int jitterThreshold: 30

            plugin: osmMapPlugin

            anchors.top: mapControl.bottom
            anchors.bottom: parent.bottom
            width: parent.width

            center {
                // Sydney
                latitude: -33.8665593
                longitude: 151.2086631
            }

            minimumZoomLevel: minZoom
            zoomLevel: defZoom

            onCenterChanged: startTimer()
            // onMapZoomLevelChanged: startTimer()
            onWidthChanged: startTimer()
            onHeightChanged: startTimer()
            
            function startTimer() {
                if(mapTimer.running)
                    mapTimer.running = false
                mapTimer.running = true
                busyIndicator.running = true
            }

            MouseArea {
                id: idModuleMouseDebug
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                anchors.fill: parent

                property variant lastCoordinate

                onPressed: {
                    map.lastX = mouse.x
                    map.lastY = mouse.y
                    map.pressX = mouse.x
                    map.pressY = mouse.y
                    lastCoordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y))
                }

                onPositionChanged: {
                    if (mouse.button == Qt.LeftButton) {
                        map.lastX = mouse.x
                        map.lastY = mouse.y

                        // var coordinate = map.toCoordinate(Qt.point(map.lastX,map.lastY))
                        // updateMap(coordinate.latitude, coordinate.longitude)
                    }
                }

                onDoubleClicked: {
                    var mouseGeoPos = map.toCoordinate(Qt.point(mouse.x, mouse.y));
                    var preZoomPoint = map.fromCoordinate(mouseGeoPos, false);
                    if(mouse.button === Qt.LeftButton) {
                        if(map.zoomLevel < 18)
                            map.zoomLevel = Math.floor(map.zoomLevel + 1)
                    } else if (mouse.button === Qt.RightButton) {
                        if(map.zoomLevel >= minZoom)
                            map.zoomLevel = Math.floor(map.zoomLevel - 1)
                    }
                    var postZoomPoint = map.fromCoordinate(mouseGeoPos, false);
                    var dx = postZoomPoint.x - preZoomPoint.x;
                    var dy = postZoomPoint.y - preZoomPoint.y;

                    var mapCenterPoint = Qt.point(map.width / 2.0 + dx, map.height / 2.0 + dy);
                    map.center = map.toCoordinate(mapCenterPoint);

                    map.lastX = -1;
                    map.lastY = -1;
                }
            }

            MapItemView {
                model: locationModel
                delegate: MapQuickItem {
                    id: marker
                    coordinate: QtPositioning.coordinate(lat, lon)

                    anchorPoint.x: image.width * 0.5
                    anchorPoint.y: image.height

                    sourceItem: Column {
                        Image {
                            id: image
                            width: units.gu(5)
                            height: sourceSize.height / sourceSize.width * units.gu(5)

                            Component.onCompleted: {
                                if(!noos) {
                                    image.source = "image://python/" + brand + "|" + title + "|" + colour + "|22"
                                } else {
                                    image.source = getMarker(brand)
                                    lrtext.text = title
                                }
                            }
                        }

                        Text { id: lrtext; font.bold: true }
                    }

                    MouseArea {
                        id: idMyMouseArea;
                        acceptedButtons: Qt.LeftButton
                        parent: marker
                        anchors.fill: parent

                        onPressed: {
                            // console.log("marker " + title + " was clicked, lat: " + coordinate.latitude + ", lon: " + coordinate.longitude)
                            map.center = coordinate
                            mapTimer.running = false
                            busyIndicator.running = false
                            markerPopup.open()
                        }
                    }

                    Popup {
                        id: markerPopup
                        padding: 10
                        width: units.gu(37)
                        height: titleLable.height + logoRow.height + addressLabel.height + units.gu(1)
                        x: Math.round((parent.width - width) / 2)
                        y: Math.round((parent.height - height) / 2)
                        modal: true
                        focus: true
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

                        Label {
                            id: titleLable
                            anchors.top: parent.top
                            anchors.left: parent.left
                            width: parent.width
                            text: title + "c per Litre"
                            font.bold: true
                            font.pixelSize: units.gu(4.5)
                        }

                        RowLayout {
                            id: logoRow
                            width: parent.width
                            anchors.top: titleLable.bottom
                            anchors.left: parent.left

                            Image {
                                id: logoImage
                                cache: false
                                anchors.top: parent.top
                                anchors.left: parent.left
                                width: units.gu(5)
                                height: units.gu(5)
                                source: getLogo(brand)
                            }

                            Label {
                                id: nameLabel
                                anchors.top: parent.top
                                anchors.left: logoImage.right
                                anchors.right: parent.right
                                width: units.gu(30)
                                text: name
                                font.bold: true
                                font.pixelSize: units.gu(3)
                                Layout.alignment: Qt.AlignRight
                                elide: Text.ElideRight
                            }
                        }

                        Label {
                            id: addressLabel
                            anchors.top: logoRow.bottom
                            anchors.left: parent.left
                            width: parent.width
                            text: address
                            wrapMode: Text.Wrap
                            font.pixelSize: units.gu(3)

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    Qt.openUrlExternally("geo:" + lat + "," + lon + "?z=18")
                                }
                            }

                        }
                    }
                }
            }
        }
    }

    Page {
        id: listPage
        visible: false
        anchors.fill: parent

        header: PageHeader {
            id: listHeader
            title: 'NSW Fuel Check'

            trailingActionBar {
                actions: [
                    Action {
                        iconName: "map"
                        text: "Show Map"

                        onTriggered: switchDisplay()
                    },
                    Action {
                        iconName: "info"
                        text: "About App"

                        onTriggered: aboutPopup2.open()
                    },
                    Action {
                        id: gps2
                        iconSource: "../assets/gps_empty.svg"
                        text: "GPS Lock"

                        onTriggered: gpsToggle()
                    }
                ]
            }
        }

        Popup {
            id: aboutPopup2
            padding: 10
            width: units.gu(37)
            height: about2a.height + about2b.height + about2c.height + about2d.height + about2Button.height + units.gu(1)
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            z: listPage.z + 6
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

            Text {
                id: about2a
                anchors.top: parent.top
                anchors.left: parent.left
                font.bold: true
                font.pixelSize: units.gu(4.5)
                text: "About this app"
            }

            Text {
                id: about2b
                padding: units.gu(1)
                anchors.top: about2a.bottom
                width: parent.width
                wrapMode: Text.Wrap
                text: "NSW Fuel Check provides real-time information about fuel prices at service stations across NSW and is accessible on any device connected to the internet, including smartphones, tablets, desk top computers and laptops."
            }

            Text {
                id: about2c
                padding: units.gu(1)
                anchors.top: about2b.bottom
                width: parent.width
                wrapMode: Text.Wrap
                font.bold: true
                text: "Warning: Never use your phone while driving, traffic penalties may apply."
            }

            Text {
                id: about2d
                padding: units.gu(1)
                anchors.top: about2c.bottom
                width: parent.width
                wrapMode: Text.Wrap
                font.bold: true
                text: "Note: This is an unofficial app, and is in no way connected with the NSW Government."
            }

            Button {
                id: about2Button
                anchors.top: about2d.bottom
                width: parent.width
                text: "Okay"
                color: "#3eb34f"
                onClicked: {
                    aboutPopup2.close()
                }
            }
        }

        ComboBox {
            id: listControl
            z: listView.z + 1
            anchors.top: listHeader.bottom
            anchors.left: parent.left
            width: parent.width
            height: units.gu(5)
            font.pixelSize: units.gu(3.5)
            model: ["Unleaded 91", "Ethanol 94 (E10)", "Ethanol 105 (E85)", "Premium 95", "Premium 98", "Diesel",
                    "Premium Diesel", "Biodiesel 20", "LPG", "CNG/NGV", "EV charge"]

            delegate: ItemDelegate {
                width: listControl.width
                contentItem: Text {
                    text: modelData
                    font.pixelSize: units.gu(3.5)
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
                highlighted: listControl.highlightedIndex === index
            }

            onCurrentIndexChanged: {
                if(currentIndex < 0)
                    currentIndex = 0
                else if(currentIndex > 10)
                    currentIndex = 0

                if(booted)
                    pytest.call("main.save_config", [map.center.latitude, map.center.longitude, map.zoomLevel, fueltype, gpsLock], function(results) {})

                mapControl.currentIndex = currentIndex
                mapControl.displayText = textAt(currentIndex)
                listControl.displayText = textAt(currentIndex)

                switch(currentIndex) {
                    case 0:
                        fueltype = "U91"
                        break
                    case 1:
                        fueltype = "E10"
                        break
                    case 2:
                        fueltype = "E85"
                        break
                    case 3:
                        fueltype = "P95"
                        break
                    case 4:
                        fueltype = "P98"
                        break
                    case 5:
                        fueltype = "DL"
                        break
                    case 6:
                        fueltype = "PDL"
                        break
                    case 7:
                        fueltype = "B20"
                        break
                    case 8:
                        fueltype = "LPG"
                        break
                    case 9:
                        fueltype = "CNG"
                        break
                    case 10:
                        fueltype = "EV"
                        break
                }

                busyIndicator.running = true
                updateMap()
            }
        }

        ListView {
            id: listView
            anchors.top: listControl.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            model: locationModel
            delegate: ItemDelegate {
                width: parent.width
                height: units.gu(5)

                RowLayout {
                    width: parent.width
                    Label {
                        text: title
                        font.bold: true
                        font.pixelSize: units.gu(3.5)
                    }
                    Image {
                        width: units.gu(2.5)
                        height: units.gu(2.5)
                        source: getLogo(brand)
                    }
                    Column {
                        width: units.gu(25)
                        height: units.gu(4)
                        Text { text: name; font.pixelSize: units.gu(2.5); verticalAlignment: Text.AlignBottom }
                        Text { text: address; font.pixelSize: units.gu(1.5); verticalAlignment: Text.AlignTop }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Qt.openUrlExternally("geo:" + lat + "," + lon + "?z=18")
                        }
                    }
                }
            }
        }
    }

    function gpsToggle() {
        if(gpsLock) {
            gpsLock = 0
            positionSource.stop()
            gps1.iconSource = "../assets/gps_empty.svg"
            gps2.iconSource = "../assets/gps_empty.svg"
        } else {
            gpsLock = 1
            positionSource.start()
            gps1.iconSource = "../assets/gps_target.svg"
            gps2.iconSource = "../assets/gps_target.svg"
        }

        if(booted)
            pytest.call("main.save_config", [map.center.latitude, map.center.longitude, map.zoomLevel, fueltype, gpsLock], function(results) {})
    }

    function switchDisplay() {
        if(mapPage.visible) {
            mapPage.visible = false
            listPage.visible = true
        } else {
            listPage.visible = false
            mapPage.visible = true
        }
    }

    ListModel {
        id: locationModel
    }

    PositionSource {
        id: positionSource
        active: true
        updateInterval: 1000
        preferredPositioningMethods: PositionSource.SatellitePositioningMethods

        onPositionChanged: {
            if(isNaN(position.coordinate.longitude) || isNaN(position.coordinate.latitude))
                return

            if(position.coordinate.latitude == 0 && position.coordinate.longitude == 0)
                return

            if(!gpsLock)
                active = false

            map.center = position.coordinate
            console.log("lastCoords: " + position.coordinate.latitude + ", " + position.coordinate.longitude)
        }

        onSourceErrorChanged: {
            if (sourceError == PositionSource.NoError)
                return

            console.log("Source error: " + sourceError)
        }

        Component.onDestruction: {
            console.log("stopping gps before exiting...")
            positionSource.stop()
            if(booted)
                pytest.call("main.save_config", [map.center.latitude, map.center.longitude, map.zoomLevel, fueltype, gpsLock], function(results) {})
        }
    }

    function updateMap() {
        if(!booted)
            return

        var pos = QtPositioning.shapeToRectangle(map.visibleRegion)
        var trlat = pos.topLeft.latitude
        var bllon = pos.topLeft.longitude
        var bllat = pos.bottomRight.latitude
        var trlon = pos.bottomRight.longitude

        if(booted && rqsts) {
            pytest.call("main.download_json", [trlat, bllon, bllat, trlon, fueltype], function(results) {
                myFunction(results);
            })
        } else if(booted) {
            var xhr = new XMLHttpRequest();
            var url = "https://api.onegov.nsw.gov.au/FuelCheckApp/v1/fuel/prices/" +
                      "bylocation?bottomLeftLatitude=" + bllat + "&bottomLeftLongitude=" + bllon +
                      "&topRightLatitude=" + trlat + "&topRightLongitude=" + trlon +
                      "&fueltype=" + fueltype + "&brands=SelectAll"
            xhr.open("GET", url);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    myFunction(xhr.responseText)
                }
            };
            xhr.send();
        }

        if(booted)
            pytest.call("main.save_config", [map.center.latitude, map.center.longitude, map.zoomLevel, fueltype, gpsLock], function(results) {})
    }

    function dodd(myid, mystr) {
        mapControl.currentIndex = myid
        mapControl.displayText = mystr
        listControl.currentIndex = myid
        listControl.displayText = mystr
    }
    
    function updateFuelType() {
        switch(fueltype) {
            case "U91":
                dodd(0, "Unleaded 91")
                break
            case "E10":
                dodd(1, "Ethanol 94 (E10)")
                break
            case "E85":
                dodd(2, "Ethanol 105 (E85)")
                break
            case "P95":
                dodd(3, "Premium 95")
                break
            case "P98":
                dodd(4, "Premium 98")
                break
            case "DL":
                dodd(5, "Diesel")
                break
            case "PDL":
                dodd(6, "Premium Diesel")
                break
            case "B20":
                dodd(7, "Biodiesel 20")
                break
            case "LPG":
                dodd(8, "LPG")
                break
            case "CNG":
                dodd(9, "CNG/NGV")
                break
            case "EV":
                dodd(10, "EV charge")
                break
        }
    }

    function myFunction(response) {
        locationModel.clear()

        if(response == undefined || response == "") {
            busyIndicator.running = false
            return
        }

        try {
            var arr = JSON.parse(response);
            var JsonObject = arr[0]
            var lowest = parseFloat(JsonObject['Price'])
            for(var i = 1; i < arr.length; i++) {
                JsonObject = arr[i]
                if(parseFloat(JsonObject['Price']) < lowest)
                    lowest = parseFloat(JsonObject['Price'])
            }

            for(var i = 0; i < arr.length; i++) {
                var JsonObject = arr[i]
                var colour = "blue"
                if(parseFloat(JsonObject['Price']) == lowest)
                    colour = "red"

                var tmp = JsonObject["Price"].toString()
                if(tmp.indexOf(".") == -1)
                    tmp += ".0"
                                
                locationModel.append({lat: JsonObject["Lat"], lon: JsonObject["Long"], title: tmp,
                                        brand: JsonObject["Brand"].toLowerCase().replace(" ", "_").replace("-", ""),
                                        name: JsonObject["Name"], address: JsonObject["Address"], id: JsonObject["ServiceStationID"],
                                        locid: JsonObject['ServiceStationID'], colour: colour})
            }
        } catch (error) {
            // console.log(error)
        }

        busyIndicator.running = false
    }

    function getMarker(brand) {
        var lc = "../assets/" + brand + ".png"
        return lc
    }

    function getLogo(brand) {
        var lc = "../assets/logos/" + brand + ".png"
        return lc
    }
}
