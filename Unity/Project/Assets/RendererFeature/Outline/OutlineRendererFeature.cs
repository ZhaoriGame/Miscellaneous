using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class OutlineRendererFeature : ScriptableRendererFeature
{
    class OutlineRenderPass : ScriptableRenderPass
    {
        private static readonly List<ShaderTagId> s_ShaderTagIds = new List<ShaderTagId>()
        {
            new ShaderTagId("SRPDefaultUnlit"),
            new ShaderTagId("UniversalForward"),
            new ShaderTagId("UniversalForwardOnly")
        };

        private static readonly int s_ShaderProp_OutlineMask = Shader.PropertyToID("_OutlineMask");
        
        private Material m_OutlineMaterial;
        private readonly FilteringSettings m_FilteringSettings;
        private readonly MaterialPropertyBlock m_PropertyBlock;
        private RTHandle m_OutlineMastRT;

        public OutlineRenderPass(Material outlineMaterial)
        {
            // Configures where the render pass should be injected.
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
            m_OutlineMaterial = outlineMaterial;
            m_FilteringSettings = new FilteringSettings(RenderQueueRange.all, renderingLayerMask: 2);
            m_PropertyBlock = new MaterialPropertyBlock();
        }
        
        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ResetTarget();
            var desc = renderingData.cameraData.cameraTargetDescriptor;
            //抗锯齿开低
            desc.msaaSamples = 1;
            //不考虑深度
            desc.depthBufferBits = 0;
            //保证渲染通道
            desc.colorFormat = RenderTextureFormat.ARGB32;
            RenderingUtils.ReAllocateIfNeeded(ref m_OutlineMastRT, desc, name: "_OutlineMaskRT");
        }

        public void Dispose()
        {
            m_OutlineMastRT?.Release();
            m_OutlineMastRT = null;

        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = CommandBufferPool.Get("Outline Command");

            cmd.SetRenderTarget(m_OutlineMastRT);
            cmd.ClearRenderTarget(true,true,Color.clear);
            var drawingSettings = CreateDrawingSettings(s_ShaderTagIds,ref renderingData,SortingCriteria.None);
            var renderListParams =
                new RendererListParams(renderingData.cullResults, drawingSettings, m_FilteringSettings);
            var list = context.CreateRendererList(ref renderListParams);
            cmd.DrawRendererList(list);
            
            //Draw outline
            cmd.SetRenderTarget(renderingData.cameraData.renderer.cameraColorTargetHandle);
            m_PropertyBlock.SetTexture(s_ShaderProp_OutlineMask,m_OutlineMastRT);
            cmd.DrawProcedural(Matrix4x4.identity, m_OutlineMaterial,0,MeshTopology.Triangles,3,1,m_PropertyBlock);
            
            
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }

    [SerializeField]private Material m_OutlineMaterial;
    OutlineRenderPass m_OutlinePass;

    public bool IsMaterialValid =>
        m_OutlineMaterial && m_OutlineMaterial.shader && m_OutlineMaterial.shader.isSupported;

    /// <inheritdoc/>
    public override void Create()
    {
        if (!IsMaterialValid)
        {
            return;
        }
        
        m_OutlinePass = new OutlineRenderPass(m_OutlineMaterial);

       
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (m_OutlinePass == null)
        {
            return;
        }
        renderer.EnqueuePass(m_OutlinePass);
    }

    protected override void Dispose(bool disposing)
    {
        base.Dispose(disposing);
        m_OutlinePass?.Dispose();
    }
}


