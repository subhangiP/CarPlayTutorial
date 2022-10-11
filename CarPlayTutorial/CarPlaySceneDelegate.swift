//
//  CarPlaySceneDelegate.swift
//  CarPlayTutorial
//
//  Created by Jordan Montel on 14/07/2021.
//

import CarPlay
import UIKit
import AVKit
import MediaPlayer

class CarPlaySceneDelegate: UIResponder  {

    // MARK: - Properties
    var interfaceController: CPInterfaceController?
    var radios = [Radio]()
    let radioListTemplate: CPListTemplate = CPListTemplate(title: "Radios", sections: [])
    let favoriteRadiosListTemplate: CPListTemplate = CPListTemplate(title: "Favorites", sections: [])
    var player = AVPlayer()
    
    // MARK: - Custom Methods
    func updateRadiosList(onlyWithFavorites: Bool) -> CPListSection {
        var radioItems = [CPListItem]()
        for radio in (onlyWithFavorites ? DataManager.shared.favoriteRadios : radios) {
            let item = CPListItem(text: radio.title, detailText: radio.subtitle)
            item.accessoryType = .disclosureIndicator
            item.setImage(UIImage(named: radio.imageSquareUrl))
            item.handler = { [weak self] item, completion in
                guard let strongSelf = self else { return }
                strongSelf.favoriteAlert(radio: radio, completion: completion)
            }
            radioItems.append(item)
        }
        return CPListSection(items: radioItems)
    }
    
    func setPlayerNowPlayingInformation(radio: Radio) {
        let stationUrl = Bundle.main.url(forResource: "Insomnia", withExtension: "mp3")
        //let stationUrl = URL(string: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3")
        let asset = AVAsset(url: stationUrl!)
        player = AVPlayer(playerItem: AVPlayerItem(asset: asset))
        player.rate = 1.0
        //player.play()
        
        var nowPlayingInfo: [String: Any] = [:]

        nowPlayingInfo = [MPMediaItemPropertyTitle: radio.title,
                         MPMediaItemPropertyArtist: radio.subtitle,
                     MPMediaItemPropertyAlbumTitle: "1989",
                          MPMediaItemPropertyGenre: "Pop",
                    MPMediaItemPropertyReleaseDate: "2014",
               MPMediaItemPropertyPlaybackDuration: CMTimeGetSeconds(asset.duration),
              //MPNowPlayingInfoPropertyIsLiveStream: true,
       MPNowPlayingInfoPropertyDefaultPlaybackRate: 1,
              MPNowPlayingInfoPropertyPlaybackRate: 1]//,
//        MPNowPlayingInfoPropertyPlaybackQueueCount: 13,
  //      MPNowPlayingInfoPropertyPlaybackQueueIndex: 3]
        
        if let image = UIImage (named: "RTSOptionMusique_square") {
            nowPlayingTemplate.tabImage = image
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size -> UIImage in
                return image
            })
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        MPNowPlayingInfoCenter.default().playbackState = .playing
        
        //nowPlayingTemplate.isUpNextButtonEnabled = true
        //nowPlayingTemplate.isAlbumArtistButtonEnabled = true
        self.setupNowPlayingInfoCenter()
        self.interfaceController?.pushTemplate(nowPlayingTemplate, animated: true, completion: nil)
    }
    
    func setupNowPlayingInfoCenter(){
        UIApplication.shared.endReceivingRemoteControlEvents()
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] event in
            print("play from carplay : \(event)")
            MPNowPlayingInfoCenter.default().playbackState = .playing
            self?.player.play()
            MPMusicPlayerController.applicationQueuePlayer.play()
          return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] event in
            print("pause from carplay : \(event)")
            MPNowPlayingInfoCenter.default().playbackState = .paused
            self?.player.pause()
            MPMusicPlayerController.applicationQueuePlayer.pause()
          return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        
      }
    
    
    func favoriteAlert(radio: Radio, completion: @escaping () -> Void) {
//        self.nowPlayingTemplate.tabTitle = radio.title
//        self.nowPlayingTemplate.upNextTitle = radio.subtitle
//        self.nowPlayingTemplate.isAlbumArtistButtonEnabled = true
//        let item = CPListItem(text: "Title", detailText: "Detail text")
//        item.isPlaying = false

        self.setPlayerNowPlayingInformation(radio: radio)
        completion()
        
        /*self.interfaceController?.pushTemplate(self.nowPlayingTemplate, animated: true, completion: { status, error in
            self.setPlayer()
            completion()
        })*/
        /*let okAlertAction: CPAlertAction = CPAlertAction(title: "Ok", style: .default) { _ in
            DataManager.shared.updateFavoriteRadios(radio: radio)
            NotificationCenter.default.post(name: .updateFavoriteRadiosNotification, object: nil)
            self.interfaceController?.dismissTemplate(animated: true, completion: { _, _ in })
        }
        let titleAlert = DataManager.shared.favoriteRadios.contains(where: {$0.uid == radio.uid}) ? "Remove from favorite" : "Add to favorite"
        let alertTemplate: CPAlertTemplate = CPAlertTemplate(titleVariants: [titleAlert], actions: [okAlertAction])
        self.interfaceController?.presentTemplate(alertTemplate, animated: true, completion: { _, _ in
            completion()
        })*/
    }
    
}

// MARK: - CPTemplateApplicationSceneDelegate
extension CarPlaySceneDelegate: CPTemplateApplicationSceneDelegate {
    
    var nowPlayingTemplate : CPNowPlayingTemplate {
        return CPNowPlayingTemplate.shared
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        
        self.interfaceController = interfaceController
        self.interfaceController?.delegate = self
                
        let rateButton = CPNowPlayingPlaybackRateButton() { button in
            //update music play rate
            print("update rate")
            
        }
        
        let repeatButton = CPNowPlayingRepeatButton() { button in
            print("repeat button")
            
        }
        
        let playButton = CPNowPlayingButton() { button in
            print("play button")
        }

        nowPlayingTemplate.updateNowPlayingButtons([rateButton, repeatButton, playButton])
        
        // Notifications
        NotificationCenter.default.addObserver(forName: .updateFavoriteRadiosNotification, object: nil, queue: nil) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.favoriteRadiosListTemplate.updateSections([strongSelf.updateRadiosList(onlyWithFavorites: false)])
        }
        
        // First download
        DataManager.shared.getRadios(completionHandler: { currentRadios in
            self.radios = currentRadios ?? []
            
            // Create a radio list
            radioListTemplate.updateSections([updateRadiosList(onlyWithFavorites: false)])
            radioListTemplate.tabImage = UIImage(named: "radio")
            
            // Create a favorite radios list
            favoriteRadiosListTemplate.updateSections([updateRadiosList(onlyWithFavorites: true)])
            favoriteRadiosListTemplate.tabImage = UIImage(named: "half_favorite")

            // Create a tab bar
            let tabBar = CPTabBarTemplate.init(templates: [radioListTemplate, favoriteRadiosListTemplate])
            tabBar.delegate = self
            self.interfaceController?.setRootTemplate(tabBar, animated: true, completion: {_, _ in })
        })
    }

    
    // CarPlay disconnected    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}

// MARK: - CPTabBarTemplateDelegate
extension CarPlaySceneDelegate: CPTabBarTemplateDelegate {
    func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {

    }
}

// MARK: - CPInterfaceControllerDelegate
extension CarPlaySceneDelegate: CPInterfaceControllerDelegate {

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateWillAppear", aTemplate)
        
        if aTemplate == favoriteRadiosListTemplate {
            favoriteRadiosListTemplate.updateSections([updateRadiosList(onlyWithFavorites: true)])
        }
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateDidAppear", aTemplate)
        
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateWillDisappear", aTemplate)
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        print("templateDidDisappear", aTemplate)
        if aTemplate == CPNowPlayingTemplate.shared {
            if (MPNowPlayingInfoCenter.default().playbackState == .playing) {
                self.player.pause()
            }
        }
    }
}
