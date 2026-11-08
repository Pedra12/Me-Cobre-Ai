# Combate Zombie 3D — Port Godot

Este é o início da migração nativa do jogo HTML/Three.js para Godot 4.7.2 estável.

## O que já foi portado nesta primeira base

- Cidade noturna com cruzamento de ruas, parque central, fonte, postes e quarteirões.
- 32 estruturas com paredes, aberturas de entrada e móveis internos simples.
- Personagem FPS com câmera, movimentação, mira, pulo e armas.
- Três classes de arma com carregadores, reserva e recarga.
- Zumbis com modelos 3D rigados do Quaternius Zombie Apocalypse Kit e seleção automática de animações idle/walk/attack/hit/death quando disponíveis; fallback procedural, dano, tipos walker/runner/brute e hordas progressivas.
- HUD Android com joystick, toque para olhar, tiro, mira, pulo, recarga e troca de arma.
- Preset Android ARM64 e workflow de APK.

## Recursos gráficos CC0 integrados no APK

O workflow baixa modelos GLB do Kenney City Kit Suburban (via FPS Buildings Environment Kit) e materiais PBR 1K do ambientCG: asfalto, tijolo, concreto e grama. As licenças publicadas pelas fontes são CC0. Os modelos externos são usados como cenário distante e vegetação; as construções abertas com interiores continuam sendo geradas no projeto.

Fontes:
- Kenney City Kit Suburban: https://kenney.nl/assets/city-kit-suburban
- Coleção de modelos: https://github.com/petroulacl/fps-buildings-env-kit
- Modelos e animações Zombie Apocalypse Kit: https://quaternius.com/packs/zombieapocalypsekit.html (espelho de arquivos: https://github.com/agentkaerf/FreeModels)
- Materiais PBR ambientCG: https://ambientcg.com/
- Licença ambientCG: https://docs.ambientcg.com/license/

## Limites desta etapa

Esta é uma conversão funcional inicial dos sistemas centrais, não uma cópia binária do Three.js. Os modelos atuais são procedurais e servem como placeholders. Ainda faltam importar modelos HD licenciados, texturas PBR dedicadas, animações esqueléticas, áudio, pickups detalhados, minimapa e o modo cooperativo PeerJS (que precisará ser refeito com uma solução de rede compatível com Godot).

## Abrir no editor

Abra a pasta `godot/` no Godot 4.7.2. O projeto usa o renderizador Mobile para priorizar Android. Execute a cena principal para testar teclado/mouse; em Android, o HUD oferece os controles por toque.

## APK automático

O workflow `.github/workflows/godot-android.yml` exporta um APK de depuração ARM64 quando há alterações na pasta `godot/` da branch `godot-4-port`.
